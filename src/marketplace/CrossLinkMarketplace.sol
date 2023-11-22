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

error Unauthorized();
error NotForSale();
error ExecutionFailed();

contract CrossLinkMarketplace is ChainlinkAppDataLayer {

    address immutable public tokenPayment;

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

    event Cancel(
        address indexed userAddress, 
        address tokenAddress, 
        uint256 tokenId
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
            
    function cancelListing(address tokenAddress, uint256 tokenId) external {
        address _listedBy = _listingDetails[tokenAddress][tokenId].listedBy;
        if (msg.sender != _listedBy) {
            revert Unauthorized();
        }

        _listingDetails[tokenAddress][tokenId] = ListingDetails ({
            chainIdSelector: 0,
            listedBy: address(0),
            price: 0
        });

        IERC721(tokenAddress).safeTransferFrom(address(this), msg.sender, tokenId);

        bytes memory data = _encodeListingData(tokenAddress, tokenId);
        _syncData(data);

        emit Cancel(msg.sender, tokenAddress, tokenId);
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

        // sync data listed
        bytes memory delistNftData = _encodeListingData(tokenAddress, tokenId);
        _syncData(delistNftData);

        if (saleType == SaleType.Native) {
            IERC20(tokenPayment).transferFrom(msg.sender, _listedBy, _listingPrice);
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
            bytes memory encodedSaleMessage = _encodeSaleData(tokenAddress, tokenId, msg.sender);
            bytes[] memory _appMessage = new bytes[](1);
            _appMessage[0] = encodedSaleMessage;
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
        return abi.encode(tokenAddress, tokenId, _listingDetails[tokenAddress][tokenId]);
    }

    function _decodeListingData(bytes memory data) internal pure returns (
        address tokenAddress, 
        uint256 tokenId,
        ListingDetails memory detail) 
    {
        (tokenAddress, tokenId, detail) = abi.decode(data, (address, uint256, ListingDetails));
    }

    function _encodeSaleData(address tokenAddress, uint256 tokenId, address _newOwner) internal view returns (bytes memory) {
        CrossChainSale memory _crossChainSale = CrossChainSale ({
            saleChainIdSelector: chainIdThis,
            newOwner: _newOwner
        });
        return abi.encode(tokenAddress, tokenId, _listingDetails[tokenAddress][tokenId], _crossChainSale);
    }

    function _decodeSaleData(bytes memory data) 
        internal 
        pure 
        returns (
            address tokenAddress, 
            uint256 tokenId, 
            CrossChainSale memory ccSale
    ) {
        (tokenAddress, tokenId, , ccSale) = abi.decode(data, (address, uint256, ListingDetails, CrossChainSale));
    }

    function _executeAppMessage(bytes[] memory encodedMessage) internal override {
        for (uint8 i = 0; i < encodedMessage.length; i++) {
            (address tokenAddress, uint256 tokenId, CrossChainSale memory ccSale) = _decodeSaleData(encodedMessage[i]);
            _transferNftToBuyer(tokenAddress, ccSale.newOwner, tokenId);
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
        (address tokenAddress, uint256 tokenId, ListingDetails memory detail) = _decodeListingData(data);
        _listingDetails[tokenAddress][tokenId] = detail;

        emit Listing(detail.chainIdSelector, detail.listedBy, tokenAddress, tokenId, detail.price);
    }
}