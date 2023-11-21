// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/token/ERC20/IERC20.sol";
import {TrustedSender} from "./TrustedSender.sol";

abstract contract ChainlinkApp is CCIPReceiver, TrustedSender {
    error UnauthorizedChainSelector();
    error FailedToWithdrawEth(address owner, address target, uint256 value);

    uint64 immutable public chainIdThis;
    bytes4 constant rootMessageId = 0x524f4f54; // ROOT

    event MessageSent(bytes32 messageId, bytes data);

    event MessageReceived(bytes32 messageId, bytes data);

    constructor (uint64 _chainIdThis, address _router) CCIPReceiver(_router) {
        CrossChainMetadataAddress memory _metadata = getConfigFromNetwork(_chainIdThis);

        chainIdThis = _chainIdThis;

        LinkTokenInterface(_metadata.linkToken).approve(_metadata.ccipRouter, type(uint256).max);
    }

    /****************************************************************/
    /********************** Encode & Decode *************************/
    /****************************************************************/

    function _encodeAppMessage(uint64[] memory bestRoutes, bytes[] memory encodedMessage) internal pure returns (bytes memory) {
        bytes memory appMessage = abi.encode(bestRoutes, encodedMessage);
        bytes memory encodedAppMessageWithRootId = abi.encode(rootMessageId, appMessage);
        return encodedAppMessageWithRootId;
    }

    function _decodeAppMessage(bytes memory encodedAppMessage) internal pure returns (uint64[] memory bestRoutes, bytes[] memory encodedMessage) {
        (, bytes memory appMessage) = abi.decode(encodedAppMessage, (bytes4, bytes));
        (bestRoutes, encodedMessage) = abi.decode(appMessage, (uint64[], bytes[]));
    }

    function _executeAppMessage(bytes[] memory data) internal virtual;

    /****************************************************************/
    /********************** Execute or Forward **********************/
    /****************************************************************/

    function _executeAndForwardMessage(uint64[] memory bestRoutes, bytes[] memory encodedMessage) internal {
        // remove first array bestRoutes to determine the destination
        uint64[] memory newBestRoutes = new uint64[](bestRoutes.length - 1);
        for(uint256 i = 0; i < bestRoutes.length - 1; i++){
            newBestRoutes[i] = bestRoutes[i+1];
        }

        bytes memory encodedMessageWithRootId = _encodeAppMessage(newBestRoutes, encodedMessage);

        // Check if already at destination
        if(newBestRoutes.length > 0){
            // Send message
            uint64 chainIdNext = newBestRoutes[0];
            CrossChainMetadataAddress memory _metadataChainThis = getConfigFromNetwork(chainIdNext);

            _sendMessage(chainIdNext, _metadataChainThis.crossChainApp, encodedMessageWithRootId);
        } else {
            ( , bytes[] memory _encodedMessage) = _decodeAppMessage(encodedMessageWithRootId);
            _executeAppMessage(_encodedMessage);   
        }
    }

    function _sendMessage(uint64 toChain, address receiver, bytes memory data) internal virtual returns (bytes32 messageId) {
        CrossChainMetadataAddress memory _metadataChainThis = getConfigFromNetwork(chainIdThis);

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: data,
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: "",
            feeToken: _metadataChainThis.linkToken
        });

        messageId = IRouterClient(_metadataChainThis.ccipRouter).ccipSend(
            toChain,
            message
        );

        emit MessageSent(messageId, data);
        return messageId;
    }

    function _ccipReceive(
        Client.Any2EVMMessage memory message
    ) internal virtual override {
        uint64 sourceChainSelector = message.sourceChainSelector; // fetch the source chain identifier (aka selector)
        address sender = abi.decode(message.sender, (address)); // abi-decoding of the sender address

        // Trusted Sender check
        if (!isTrustedSender(sourceChainSelector,sender)) {
            revert UnauthorizedChainSelector();
        }
        
        (uint64[] memory bestRoutes, bytes[] memory encodedMessage) = _decodeAppMessage(message.data);
        _executeAndForwardMessage(bestRoutes, encodedMessage);

        emit MessageReceived(message.messageId, message.data);
    }

    function withdrawToken(
        address beneficiary,
        address token
    ) public onlyOwner {
        uint256 amount = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(beneficiary, amount);
    }
    
}