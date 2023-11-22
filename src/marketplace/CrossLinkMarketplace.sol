// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {ChainlinkAppDataLayer} from "../chainlink-app/extension/ChainlinkAppDataLayer.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITokenProxySource {
    function lockAndMint(uint64[] memory bestRoutes ,address tokenReceiver, uint256 amount) external;
}

interface ITokenProxyDestination {
    function burnAndMintOrUnlock(uint64[] memory bestRoutes ,address tokenReceiver, uint256 amount) external;
}

interface INFT {
    function name() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory); 
}

error Unauthorized();
error NotForSale();
error ExecutionFailed();

contract CrossLinkMarketplace is ChainlinkAppDataLayer {

    address immutable public tokenPayment;
    bytes4 immutable public listingMessageId = 0x00000001;
    bytes4 immutable public saleMessageId = 0x00000002;

    enum SaleType {
        Native,
        CrossChain
    }

    struct ListingDetails {
        uint64 chainIdSelector;
        address listedBy;
        uint256 price;
    }
    mapping(address => mapping(uint256 => ListingDetails)) private _listingDetails; // tokenAddress => tokenId => ListingDetails

    struct CrossChainSale {
        uint64 saleChainIdSelector;
        address prevOwner;
        address newOwner;
    }

    event Listing(
        uint64 indexed chainIdSelector,
        address indexed ownerAddress, 
        address indexed tokenAddress,
        uint256 tokenId,
        uint256 price
    );

    event Sale(
        SaleType indexed saleType,
        address indexed tokenAddress, 
        uint64 saleChainIdSelector,
        uint64 originChainIdSelector,
        address newOwner,
        address prevOwner, 
        uint256 tokenId,
        uint256 price
    );

    constructor(
        uint64 _chainIdThis, 
        uint64 _chainIdMaster, 
        address _router, 
        address _tokenPayment
    ) ChainlinkAppDataLayer(_chainIdThis, _chainIdMaster, _router) {
        tokenPayment = _tokenPayment;
    }

    receive() external payable {}   

    function listing(address tokenAddress, uint256 tokenId, uint256 _price) external {
        IERC721(tokenAddress).safeTransferFrom(msg.sender, address(this), tokenId);

        _listingDetails[tokenAddress][tokenId] = ListingDetails ({
            chainIdSelector: chainIdThis,
            listedBy: msg.sender,
            price: _price
        });

        bytes memory encodedListingMessage = _encodeListingData(tokenAddress, tokenId);
        _syncData(encodedListingMessage);

        emit Listing(chainIdThis, msg.sender, tokenAddress, tokenId, _price);
    }

    function buy(SaleType saleType, uint64[] memory bestRoutes, address tokenAddress, uint256 tokenId) external {    
        uint64 _chainIdOrigin = _listingDetails[tokenAddress][tokenId].chainIdSelector;
        address _listedBy = _listingDetails[tokenAddress][tokenId].listedBy;
        uint256 _listingPrice = _listingDetails[tokenAddress][tokenId].price;

        if (_listedBy == address(0)) {
            revert NotForSale();
        }

        _listingDetails[tokenAddress][tokenId] = ListingDetails ({
            chainIdSelector: 0,
            listedBy: address(0),
            price: 0
        });

        // sync data sale
        _syncData(_encodeSaleData(tokenAddress, tokenId, _listedBy, msg.sender));

        IERC20(tokenPayment).transferFrom(msg.sender, _listedBy, _listingPrice);

        if (saleType == SaleType.Native) {
            IERC721(tokenAddress).safeTransferFrom(address(this), msg.sender, tokenId);

            emit Sale(
                SaleType.Native, 
                tokenAddress, 
                chainIdThis, 
                chainIdThis, 
                msg.sender, 
                _listedBy, 
                tokenId, 
                _listingPrice
            );

        } else {
            ListingDetails memory detail = _listingDetails[tokenAddress][tokenId];
          
            // Move nft & execute in multihop 
            bytes[] memory _appMessage = new bytes[](1);
            _appMessage[0] = _encodeSaleData(tokenAddress, tokenId, _listedBy, msg.sender);
            _executeAndForwardMessage(bestRoutes, _appMessage);

            if (chainIdThis == chainIdMaster) {
                ITokenProxySource(tokenPayment).lockAndMint(bestRoutes, _listedBy,_listingPrice);
            } else {
                ITokenProxyDestination(tokenPayment).burnAndMintOrUnlock(bestRoutes, _listedBy,_listingPrice);
            }

            emit Sale(
                SaleType.CrossChain, 
                tokenAddress, 
                chainIdThis, 
                _chainIdOrigin, 
                msg.sender, 
                detail.listedBy, 
                tokenId, 
                detail.price
            );
        }
    }

    function checkListedNftDetails(address tokenAddress, uint256 tokenId) external view returns (ListingDetails memory) {
        return _listingDetails[tokenAddress][tokenId];
    }

    function _encodeListingData(address tokenAddress, uint256 tokenId) internal view returns (bytes memory) {
        bytes memory encodedListingData = abi.encode(
            tokenAddress, 
            tokenId, 
            _listingDetails[tokenAddress][tokenId]
        );
        return abi.encode(listingMessageId, encodedListingData);
    }

    function _decodeListingData(bytes memory data) internal pure returns (
        address tokenAddress, 
        uint256 tokenId,
        ListingDetails memory listingDetail
    ) {
        (tokenAddress, tokenId, listingDetail) = abi.decode(data, (address, uint256, ListingDetails));
    }

    function _encodeSaleData(
        address tokenAddress, 
        uint256 tokenId, 
        address _prevOwner, 
        address _newOwner
    ) internal view returns (bytes memory) {
        CrossChainSale memory crossChainSale = CrossChainSale ({
            saleChainIdSelector: chainIdThis,
            prevOwner: _prevOwner,
            newOwner: _newOwner
        });

        bytes memory encodedSaleData = abi.encode(
            tokenAddress, 
            tokenId, 
            _listingDetails[tokenAddress][tokenId], 
            crossChainSale
        );
        return abi.encode(saleMessageId, encodedSaleData);
    }

    function _decodeSaleData(bytes memory data) 
        internal 
        pure 
        returns (
            address tokenAddress, 
            uint256 tokenId, 
            ListingDetails memory listingDetail,
            CrossChainSale memory crossChainSale
    ) {
        (tokenAddress, tokenId, listingDetail, crossChainSale) = abi.decode(data, (address, uint256, ListingDetails, CrossChainSale));
    }

    function _executeAppMessage(bytes[] memory encodedMessage) internal override {
        for (uint8 i = 0; i < encodedMessage.length; i++) {
            (, bytes memory encodedSaleMessage) = abi.decode(encodedMessage[i], (bytes4, bytes));
            (
                address tokenAddress, 
                uint256 tokenId, 
                , 
                CrossChainSale memory crossChainSale
            ) = _decodeSaleData(encodedSaleMessage);
            _transferNftToBuyer(tokenAddress, crossChainSale.newOwner, tokenId);
        }
    }

    function _transferNftToBuyer(address tokenAddress, address to, uint256 tokenId) internal {
        IERC721(tokenAddress).safeTransferFrom(address(this), to, tokenId);
    }

    function onERC721Received(address operator, address, uint256, bytes calldata) external view returns(bytes4) {
        require(operator == address(this), "token must be staked over list method");
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function _storeData(bytes memory data) internal override {
        (bytes4 _messageId, bytes memory encodedMessage) = abi.decode(data, (bytes4, bytes));
        
        if (_messageId == listingMessageId) {
            (
                address tokenAddress, 
                uint256 tokenId, 
                ListingDetails memory listingDetail
            ) = _decodeListingData(encodedMessage);

            _listingDetails[tokenAddress][tokenId] = listingDetail;
        } else if (_messageId == saleMessageId) {
            (
                address tokenAddress, 
                uint256 tokenId, 
                ListingDetails memory listingDetail,
            ) = _decodeSaleData(encodedMessage);

            _listingDetails[tokenAddress][tokenId] = listingDetail;
        }
    }
}