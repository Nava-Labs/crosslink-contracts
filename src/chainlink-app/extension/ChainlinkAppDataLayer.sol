// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Client, IRouterClient, ChainlinkApp} from "../ChainlinkApp.sol";

abstract contract ChainlinkAppDataLayer is ChainlinkApp {
    uint64 immutable public chainIdMaster;
    bytes4 constant syncMessageId = 0x53594e43; // SYNC

    uint256 public latestSyncTimestamp;

    event SyncDataMessage(bytes32 messageId, bytes data);

    constructor(uint64 _chainIdThis, uint64 _chainIdMaster, address _router) ChainlinkApp(_chainIdThis, _router) {
        chainIdMaster = _chainIdMaster;
    }

    function _sendToMasterOrUpdate(
        bytes memory encodedMessageWithExtensionId
    ) internal {
        (uint64 chainIdOrigin, bytes memory encodedMessage, uint256 latestSyncTime) = _decodeSyncMessageWithExtensionId(encodedMessageWithExtensionId);

        if (chainIdThis != chainIdMaster && chainIdOrigin != chainIdMaster) {
            _sendToMaster(encodedMessageWithExtensionId);
        }  else if (chainIdThis == chainIdMaster) {
            bytes memory encodedMessageWithMasterOrigin = abi.encode(chainIdMaster, encodedMessage, latestSyncTime);
            bytes memory encodedSyncMessageWithExtensionIdWithMasterOrigin = _encodeSyncMessageWithExtensionId(encodedMessageWithMasterOrigin);
            _storeData(encodedMessage);
            _distributeSyncData(chainIdOrigin, encodedSyncMessageWithExtensionIdWithMasterOrigin); // exclude origin and self
        } else if (chainIdOrigin == chainIdMaster) {
            _storeData(encodedMessage);
        }

        latestSyncTimestamp = latestSyncTime;
    }

    function _encodeSyncMessageWithExtensionId(bytes memory encodedMessageWithMasterOrigin) internal pure returns (bytes memory encodedMessageWithExtensionId) {
        bytes memory encodedMessageWithWithExtensionIdAndMasterOrigin = abi.encode(syncMessageId, encodedMessageWithMasterOrigin);
        return encodedMessageWithWithExtensionIdAndMasterOrigin;
    }

    function _decodeSyncMessageWithExtensionId(bytes memory encodedMessageWithExtensionId) internal pure returns (uint64 chainIdOrigin, bytes memory encodedMessage, uint256 latestSyncTime) {
        (, bytes memory syncMessage) = abi.decode(encodedMessageWithExtensionId, (bytes4, bytes));
        (chainIdOrigin, encodedMessage, latestSyncTime) = abi.decode(syncMessage, (uint64, bytes, uint256));
    }

    function _sendToMaster(bytes memory data) private returns (bytes32 messageId) {        
        CrossChainMetadataAddress memory _metadataChainMaster = getConfigFromNetwork(chainIdMaster);
        messageId = _sendMessage(chainIdMaster, _metadataChainMaster.crossChainApp, data);
   }

    function _sendMessage(uint64 toChain, address receiver, bytes memory data) internal override returns (bytes32 messageId) {
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

        emit SyncDataMessage(messageId, data);        
    }

    function _syncData(bytes memory encodedMessage) internal {
        bytes memory syncMessage = abi.encode(chainIdThis, encodedMessage, block.timestamp);
        bytes memory encodedMessageWithExtensionId = abi.encode(syncMessageId, syncMessage);
        _sendToMasterOrUpdate(encodedMessageWithExtensionId);
    }

    function _storeData(bytes memory data) internal virtual;

    function _distributeSyncData(uint64 excludedChain, bytes memory data) private {
        CrossChainMetadataAddress[4] memory _metadatas = getAllNetworks(); 

        // always exclude sepolia for duplication while storing data
        for(uint8 i = 1; i < _metadatas.length; i++) {
            if (_metadatas[i].chainIdSelector != excludedChain) {
                _sendMessage(_metadatas[i].chainIdSelector, _metadatas[i].crossChainApp, data);    
            }
        }
    }

    function _ccipReceive(
        Client.Any2EVMMessage memory message
    ) internal override {
        uint64 sourceChainSelector = message.sourceChainSelector; // fetch the source chain identifier (aka selector)
        address sender = abi.decode(message.sender, (address)); // abi-decoding of the sender address

        // Trusted Sender check
        if (!isTrustedSender(sourceChainSelector,sender)) {
            revert UnauthorizedChainSelector();
        }
        
        (bytes4 messageId, ) = abi.decode(message.data, (bytes4, bytes));
        
        if (messageId == syncMessageId) {
            _sendToMasterOrUpdate(message.data);
        } else {
            (uint64[] memory bestRoutes, bytes[] memory data) = _decodeAppMessage(message.data);
            _executeAndForwardMessage(bestRoutes, data);
        }

        emit MessageReceived(message.messageId, message.data);
    }
}
