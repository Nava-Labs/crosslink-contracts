// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/token/ERC20/IERC20.sol";
import {TrustedSender} from "./TrustedSender.sol";

error UnauthorizedChainSelector();
error FailedToWithdrawEth(address owner, address target, uint256 value);

abstract contract ChainlinkApp is CCIPReceiver, TrustedSender {

    uint64 immutable public chainIdThis;

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

    // function _encodeAppMessage(bytes4 selector, bytes data) internal virtual;

    function _decodeAppMessage(bytes[] memory encodedMessage) internal virtual;

    /****************************************************************/
    /********************** Execute or Forward **********************/
    /****************************************************************/

    function _executeAndForwardMessage(uint64[] memory bestRoutes, bytes[] memory encodedMessage) internal {
        // remove first array bestRoutes to determine the destination
        uint64[] memory newBestRoutes = new uint64[](bestRoutes.length - 1);
        for(uint256 i = 0; i < bestRoutes.length - 1; i++){
            newBestRoutes[i] = bestRoutes[i+1];
        }

        // Check if already at destination
        if(newBestRoutes.length > 0){
            bytes memory data = abi.encode(newBestRoutes,encodedMessage);

            // Send message
            uint64 chainIdNext = newBestRoutes[0];
            CrossChainMetadataAddress memory _metadataChainThis = getConfigFromNetwork(chainIdNext);

            _sendMessage(chainIdNext, _metadataChainThis.crossChainApp, data);

        }else{
            _decodeAppMessage(encodedMessage);
        }
    }

    function _sendMessage(uint64 toChain, address receiver, bytes memory data) internal returns (bytes32 messageId) {
        CrossChainMetadataAddress memory _metadataChainThis = getConfigFromNetwork(chainIdThis);

        Client.EVMExtraArgsV1 memory _extraArgs = Client.EVMExtraArgsV1 ({
          gasLimit: 2_000_000,
          strict: true
        });

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: data,
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(_extraArgs),
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
    ) internal override{
        uint64 sourceChainSelector = message.sourceChainSelector; // fetch the source chain identifier (aka selector)
        address sender = abi.decode(message.sender, (address)); // abi-decoding of the sender address

        // Trusted Sender check
        if (!isTrustedSender(sourceChainSelector,sender)) {
            revert UnauthorizedChainSelector();
        }
        
        (uint64[] memory bestRoutes , bytes[] memory encodedMessage) = abi.decode(message.data,(uint64[], bytes[]));
        
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