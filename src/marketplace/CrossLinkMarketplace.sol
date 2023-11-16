// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {DataProxy, IRouterClient, Client} from "../proxy/DataProxy.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error Unauthorized();

contract CrossLinkMarketplace is DataProxy, CCIPReceiver {

    enum SaleType {
        Native,
        CrossChain
    }

    struct ListingDetails {
        uint256 chainIdSelector;
        address listedBy;
        uint256 price;
    }
    mapping(address => mapping(uint256 => ListingDetails)) private _listingDetails; // tokenAddress => tokenId => ListingDetails

    // struct CrossChainSale {
    //     uint256 chainIdSelector;
    //     address newOwner;
    // }

    event Listing(
        uint256 indexed chainIdSelector,
        address indexed ownerAddress, 
        address indexed tokenAddress,
        uint256 tokenId,
        uint256 price
    );

    // event Sale(
    //     SaleType indexed saleType,
    //     uint256 indexed chainIdSelector,
    //     address indexed tokenAddress, 
    //     address newOwner,
    //     address prevOwner, 
    //     uint256 tokenId,
    //     uint256 price
    // );

    event Cancel(
        address indexed userAddress, 
        address tokenAddress, 
        uint256 tokenId
    );

    event MessageSent(bytes32 messageId, bytes data);

    event MessageReceived(bytes32 messageId, bytes data);

    constructor(uint64 _chainIdThis, uint64 _chainIdMaster, address routerThis) CCIPReceiver(routerThis) DataProxy(_chainIdThis, _chainIdMaster) {}

    receive() external payable {}   

    function listing(address tokenAddress, uint256 tokenId, uint256 _price) external {
        // IERC721(tokenAddress).safeTransferFrom(msg.sender, address(this), tokenId);

        _listingDetails[tokenAddress][tokenId] = ListingDetails ({
            chainIdSelector: chainIdThis,
            listedBy: msg.sender,
            price: _price
        });

        bytes memory data = _encodeListingData(tokenAddress, tokenId);
        _syncData(chainIdThis, data);
        emit Listing(chainIdThis, msg.sender, tokenAddress, tokenId, _price);
    }
            
    function cancelListing(address tokenAddress, uint256 tokenId) external {
        address _listedBy = _listingDetails[tokenAddress][tokenId].listedBy;
        if (msg.sender != _listedBy) {
            revert Unauthorized();
        }

        _listingDetails[tokenAddress][tokenId] = ListingDetails ({
            chainIdSelector: chainIdThis,
            listedBy: address(0),
            price: 0
        });

        // IERC721(tokenAddress).safeTransferFrom(address(this), msg.sender, tokenId);

        emit Cancel(msg.sender, tokenAddress, tokenId);
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

    function _ccipReceive(
        Client.Any2EVMMessage memory message
    ) internal override {
        _sendToMasterOrUpdate(message.data);
        emit MessageReceived(message.messageId, message.data);
    }

    function onERC721Received(address operator, address, uint256, bytes calldata) external view returns(bytes4) {
        require(operator == address(this), "token must be staked over list method");
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function _storeData(bytes memory data) internal override {
        (address tokenAddress, uint256 tokenId, ListingDetails memory detail) = _decodeListingData(data);
        _listingDetails[tokenAddress][tokenId] = detail;
    }
}
