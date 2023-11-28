// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {CRC1Syncable} from "ccip/CRC1/extensions/CRC1Syncable.sol";
import {ICRC20Source} from "ccip/CRC20/interfaces/ICRC20Source.sol";
import {ICRC20Destination} from "ccip/CRC20/interfaces/ICRC20Destination.sol";

interface INFT {
    function name() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory); 
}

error Unauthorized();
error NotForSale();
error ExecutionFailed();

contract NFTMarketplace is CRC1Syncable {

    // Best practice if your app use more than one message to do
    bytes4 immutable public listingMessageId = 0x00000001;
    bytes4 immutable public saleMessageId = 0x00000002;

    address public tokenPayment;

    enum SaleType {
        Native,
        CrossChain
    }

    struct NFTDetails {
        string collectionName;
        string tokenURI;
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
        string collectionName,
        uint256 tokenId,
        string tokenURI,
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
    ) CRC1Syncable(_chainIdThis, _chainIdMaster, _router) {
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

        (string memory collectionName, string memory tokenURI) = _fetchNftDetails(tokenAddress, tokenId);

        bytes memory encodedListingMessage = _encodeListingData(tokenAddress, tokenId, collectionName, tokenURI);
        /*
         * Sync the listing data across chains.
         * This is crucial for updating the contract's state across all connected chains.
         * The actual data handling is dependent on the implementation of the {storeData} function.
         */
        _syncData(encodedListingMessage);

        emit Listing(chainIdThis, msg.sender, tokenAddress, collectionName, tokenId, tokenURI, _price);
    }

    function buy(uint64[] memory bestRoutes, SaleType saleType, address tokenAddress, uint256 tokenId) external {    
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

        /*
         * Sync the sale data across chains after updating the local contract state.
         * This ensures that the sale information is consistent across all connected chains.
         * The implementation of storeData function will define how this data is processed.
         */
        _syncData(_encodeSaleData(tokenAddress, tokenId, _listedBy, msg.sender));

        IERC20(tokenPayment).transferFrom(msg.sender, address(this), _listingPrice);

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
            // Move nft & execute in multihop 
            bytes[] memory _appMessage = new bytes[](1);
            _appMessage[0] = _encodeSaleData(tokenAddress, tokenId, _listedBy, msg.sender);

            /*
             * Executes and forwards the message to enable multi-hop functionality and bundling executions.
             * By using this function, messages can be sent across multiple chains.
             * In this context, it's used to handle the cross-chain sale process.
             */
            _executeAndForwardMessage(bestRoutes, _appMessage);

            if (chainIdThis == chainIdMaster) {
                ICRC20Source(tokenPayment).lockAndMint(bestRoutes, _listedBy,_listingPrice);
            } else {
                ICRC20Destination(tokenPayment).burnAndMintOrUnlock(bestRoutes, _listedBy,_listingPrice);
            }

            emit Sale(
                SaleType.CrossChain, 
                tokenAddress, 
                chainIdThis, 
                _chainIdOrigin, 
                msg.sender, 
                _listedBy, 
                tokenId, 
                _listingPrice
            );
        }
    }

    function setTokenPayment(address _tokenPayment) external onlyOwner {
        tokenPayment = _tokenPayment;
    }

    function checkListedNftDetails(address tokenAddress, uint256 tokenId) external view returns (ListingDetails memory) {
        return _listingDetails[tokenAddress][tokenId];
    }

    function _encodeListingData(
        address tokenAddress, 
        uint256 tokenId, 
        string memory collectionName, 
        string memory tokenURI
    ) internal view returns (bytes memory) {
        NFTDetails memory nftDetails = NFTDetails ({
            collectionName: collectionName,
            tokenURI: tokenURI
        });

        bytes memory encodedListingData = abi.encode(
            tokenAddress, 
            tokenId, 
            _listingDetails[tokenAddress][tokenId],
            nftDetails
        );
        return abi.encode(listingMessageId, encodedListingData);
    }

    function _decodeListingData(bytes memory data) internal pure returns (
        address tokenAddress, 
        uint256 tokenId,
        ListingDetails memory listingDetail,
        NFTDetails memory nftDetails
    ) {
        (
            tokenAddress, 
            tokenId, 
            listingDetail, 
            nftDetails
        ) = abi.decode(data, (address, uint256, ListingDetails, NFTDetails));
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
        (
            tokenAddress, 
            tokenId, 
            listingDetail, 
            crossChainSale
        ) = abi.decode(data, (address, uint256, ListingDetails, CrossChainSale));
    }

    /*
     * Impelement the _executeAppMessage function from the CRC1.
     * Executes application-specific logic upon receiving a message via CCIP.
     * In the context of the CrossLinkMarketplace, this function is tailored to handle post-buy operations.
     * It iterates over each encoded message, decodes it to extract sale details,
     * and then transfers the NFT to the new owner as per the cross-chain sale data.
     * This is an essential part of ensuring that cross-chain transactions are completed successfully.
     */
     function _executeAppMessage(bytes[] memory encodedAppMessage) internal override {
        for (uint8 i = 0; i < encodedAppMessage.length; i++) {
            (, bytes memory encodedSaleMessage) = abi.decode(encodedAppMessage[i], (bytes4, bytes));
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

    /*
     * Impelement the _storeData function from the CRC1Sycnable.
     * This function is critical for updating the contract state in a cross-chain context.
     * It decodes the incoming data based on its messageId and updates the contract's state
     * with the new listing or sale details. Specifically, in this example, it handles the
     * updates for new listings, reflecting changes in listing details across all connected chains.
     */
    function _storeData(bytes memory data) internal override {
        (bytes4 _messageId, bytes memory encodedMessage) = abi.decode(data, (bytes4, bytes));
        
        if (_messageId == listingMessageId) {
            (
                address tokenAddress, 
                uint256 tokenId, 
                ListingDetails memory listingDetail,
                NFTDetails memory nftDetails
            ) = _decodeListingData(encodedMessage);

            _listingDetails[tokenAddress][tokenId] = listingDetail;
            emit Listing(
                listingDetail.chainIdSelector, 
                listingDetail.listedBy, 
                tokenAddress, 
                nftDetails.collectionName,
                tokenId, 
                nftDetails.tokenURI,
                listingDetail.price
            );

        } else if (_messageId == saleMessageId) {
            (
                address tokenAddress, 
                uint256 tokenId, 
                ListingDetails memory listingDetail,
                CrossChainSale memory crossChainSale            
            ) = _decodeSaleData(encodedMessage);

            _listingDetails[tokenAddress][tokenId] = listingDetail;

            emit Sale(
                SaleType.CrossChain, 
                tokenAddress, 
                crossChainSale.saleChainIdSelector, 
                listingDetail.chainIdSelector, 
                crossChainSale.newOwner,
                crossChainSale.prevOwner,
                tokenId, 
                listingDetail.price
            );
        }
    }

    function _fetchNftDetails(address tokenAddress, uint256 tokenId) 
        internal 
        view
        returns (
            string memory collectionName,
            string memory tokenURI
    ) {
        collectionName = INFT(tokenAddress).name();
        tokenURI = INFT(tokenAddress).tokenURI(tokenId);
    }
}
