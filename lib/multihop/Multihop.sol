// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
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

    // function _encodeAppMessage(bytes4 selector, bytes data) internal virtual;

    function _decodeAppMessage(bytes encodedMessage) internal virtual;


    /****************************************************************/
    /********************** Execute or Forward **********************/
    /****************************************************************/

    function _executeAndForwardMessage(string[] bestRoutes , bytes encodedMessage) internal virtual{
        // Delete array bestRoutes to determine the destination
        delete bestRoutes[0];

        // Check if already at destination
        if(bestRoutes.length > 0){
            
            bytes memory data = abi.encode(bestRoutes,encodedMessage)

            // Send message
            uint64 chainIdNext = bestRoutes[0].chainIdNext;

            _sendMessage(chainIdNext, data);

        }else{
            
            _decodeAppMessage(encodedMessage);
        }
    }

    function _sendMessage(
        uint64 chainIdNext,
        bytes memory data
    ) internal returns (bytes32 messageId) {
        // Get Router and Link
        CrossChainMetadataAddress _metadataChainThis = getConfigFromNetwork(chainIdThis);
        CrossChainMetadataAddress _metadataChainNext = getConfigFromNetwork(chainIdNext);

        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(_metadataChainNext.crossChainApp), // ABI encode next bestRoutes address
            data: data, // ABI encode message
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: "",
            feeToken: _metadataChainThis.linkToken // Setting feeToken to $LINK, as main currency for fee
        });

        // Send Messages
        messageId = IRouterClient(_metadataChainThis.ccipRouter).ccipSend(
            chainIdNext,
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