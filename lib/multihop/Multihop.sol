// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {CCIPDirectory} from "./CCIPDirectory";

abstract contract Multihop is CCIPDirectory {

    uint64 immutable public chainIdThis;

    constructor (uint64 _chainIdThis){
        CrossChainMetadataAddress _metadata = getConfigFromNetwork(_chainIdThis);

        chainIdThis = _chainIdThis

        LinkTokenInterface(_metadata.linkToken).approve(_metadata.ccipRouter, type(uint256).max);
    }
    /****************************************************************/
    /********************** Encode & Decode *************************/
    /****************************************************************/

    function _encodeAppMessage(bytes4 selector, bytes data) internal virtual;

    function _decodeAppMessage(bytes message) internal virtual;


    /****************************************************************/
    /********************** Execute or Forward **********************/
    /****************************************************************/

    function _executeAndForwardMessage(string[] bestRoutes , bytes[] encodedMessages) internal virtual{
        // Delete array bestRoutes to determine the destination
        delete bestRoutes[0];

        // Check if already at destination
        if(bestRoutes.length > 0){
            // Encode message for sending
            bytes memory data = abi.encode(bestRoutes,encodedMessages);

            // Send message
            uint64 destinationChainSelector = bestRoutes[0].destinationChainSelector;
            address messageReceiver = bestRoutes[0].messageReceiver;

            _sendMessage(destinationChainSelector, messageReceiver, data);

        }else{
            
            _decodeAppMessage(encodedMessages);
        }
    }

    function _sendMessage(
        uint64 destinationChainSelector,
        address messageReceiver,
        bytes memory data
    ) internal returns (bytes32 messageId) {
        // Get Router and Link
        CrossChainMetadataAddress _metadataChainThis = getConfigFromNetwork(chainIdThis);

        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(messageReceiver), // ABI encode next bestRoutes address
            data: data, // ABI encode message
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: "",
            feeToken: _metadataChainThis.linkToken // Setting feeToken to $LINK, as main currency for fee
        });

        // Send Messages
        messageId = IRouterClient(_metadataChainThis.ccipRouter).ccipSend(
            destinationChainSelector,
            message
        );

        return messageId;
    }

    function _ccipReceive(
        Client.Any2EVMMessage memory message
    ) internal virtual{
        (string[] memory bestRoutes , bytes encodedMessage) = abi.decode(message.data,(string[] memory,bytes))
        
        _executeAndForwardMessage(bestRoutes,encodedMessage)

    }



}