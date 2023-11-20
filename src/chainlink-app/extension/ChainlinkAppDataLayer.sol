// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Client, IRouterClient, ChainlinkApp} from "../ChainlinkApp.sol";

abstract contract ChainlinkAppDataLayer is ChainlinkApp {
    uint64 immutable public chainIdMaster;

    uint256 public latestSyncTime;

    event SyncDataMessage(bytes32 messageId, bytes data);

    constructor(uint64 _chainIdThis, uint64 _chainIdMaster, address _router) ChainlinkApp(_chainIdThis, _router) {
        chainIdMaster = _chainIdMaster;
    }

    // add this function to your ccipReceive
    function _sendToMasterOrUpdate(
        bytes memory data
    ) internal {
        (uint64[] memory bestRoutes, uint64 _chainIdOrigin, bytes memory _data, uint256 _latestSyncTime) = abi.decode(data[4:], (uint64[], uint64, bytes, uint256));

        if (chainIdThis != chainIdMaster && _chainIdOrigin != chainIdMaster) {
            _sendToMaster(data);
        }  else if (chainIdThis == chainIdMaster) {
            bytes memory encodedDataWithMasterOrigin = abi.encode(bestRoutes, chainIdMaster, _data, _latestSyncTime);
            bytes memory encodedDataWithMasterOriginWithSelector = abi.encodeWithSignature("_sendToMasterOrUpdate(bytes)", encodedDataWithMasterOrigin);
            _storeData(_data);
            latestSyncTime = _latestSyncTime;
            _distributeSyncData(_chainIdOrigin, encodedDataWithMasterOriginWithSelector); // exclude origin and self
        } else if (_chainIdOrigin == chainIdMaster) {
            _storeData(_data);
            latestSyncTime = _latestSyncTime;
        }

        latestSyncTime = block.timestamp;
    }

    function _sendToMaster(bytes memory data) private returns (bytes32 messageId) {        
        CrossChainMetadataAddress memory _metadataChainMaster = getConfigFromNetwork(chainIdMaster);
        messageId = _sendMessage(chainIdMaster, _metadataChainMaster.crossChainApp, data);
   }

    // function _sendMessage(uint64 toChain, address receiver, bytes memory data) internal returns (bytes32 messageId) {
    //     CrossChainMetadataAddress memory _metadataChainThis = getConfigFromNetwork(chainIdThis);

    //     Client.EVMExtraArgsV1 memory _extraArgs = Client.EVMExtraArgsV1 ({
    //       gasLimit: 2_000_000,
    //       strict: true
    //     });

    //     Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
    //         receiver: abi.encode(receiver),
    //         data: data,
    //         tokenAmounts: new Client.EVMTokenAmount[](0),
    //         extraArgs: Client._argsToBytes(_extraArgs),
    //         feeToken: _metadataChainThis.linkToken
    //     });

    //     messageId = IRouterClient(_metadataChainThis.ccipRouter).ccipSend(
    //         toChain,
    //         message
    //     );

    //     emit SyncDataMessage(messageId, data);        
    // }

    function _syncData(bytes memory data) internal {
        bytes memory _data = abi.encodeWithSignature("_sendToMasterOrUpdate(bytes)", data);
        _sendToMasterOrUpdate(_data);
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
}
