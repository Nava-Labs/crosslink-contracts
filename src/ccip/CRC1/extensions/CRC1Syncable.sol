// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Client, IRouterClient, CRC1} from "../CRC1.sol";

/**
 * @dev An extension of the CRC1 contract, CRC1Syncable is designed to facilitate comprehensive data synchronization across different blockchain networks. 
 * It serves as a crucial data layer for applications that require consistent state management and data harmonization across multiple chains.
 *
 * This contract manages the process of ensuring that all contracts across all chains maintain an updated and synchronized state.
 *
 * Key Element:
 * - `latestSyncTimestamp`: A public variable that holds the timestamp of the most recent data synchronization event. 
 * This timestamp is essential for establishing data finality.
 *
 * The sync process typically involves sending data to a master chain, which then orchestrates the distribution and synchronization
 * across other chains.
 */
abstract contract CRC1Syncable is CRC1 {
    uint64 immutable public chainIdMaster; // Master chain ID for data synchronization
    bytes4 constant syncMessageId = 0x53594e43; // SYNC - Identifier for sync messages

    uint256 public latestSyncTimestamp; // Timestamp of the latest data sync, used for data finality

    event SyncDataMessage(bytes data); // Event emitted when sync data is synced

    constructor(uint64 _chainIdThis, uint64 _chainIdMaster, address _router) CRC1(_chainIdThis, _router) {
        chainIdMaster = _chainIdMaster;
    }

    /*
     * Decides whether to send the encodedData to the master chain or update the current state for data synchronization.
     * Checks the origin of the message.
     */
    function _sendToMasterOrUpdate(
        bytes memory encodedDataWithExtensionId
    ) internal {
        (
            uint64 chainIdOrigin, 
            bytes memory encodedData, 
            uint256 latestSyncTime
        ) = _decodeSyncDataWithExtId(encodedDataWithExtensionId);

        if (chainIdThis != chainIdMaster && chainIdOrigin != chainIdMaster) {
            _sendToMaster(encodedDataWithExtensionId);
        }  else if (chainIdThis == chainIdMaster) {            
            bytes memory encodedDataWithMasterOrigin = abi.encode(chainIdMaster, encodedData, latestSyncTime);
            bytes memory encodedDataWithExtIdAndMasterOrigin = 
                _encodeSyncDataWithExtId(encodedDataWithMasterOrigin);

            // avoid doubling storing data if origin == master
            if (chainIdOrigin == chainIdMaster) {
                _distributeSyncData(chainIdOrigin, encodedDataWithExtIdAndMasterOrigin); // exclude origin and self
            } else {
                _storeData(encodedData);
                _distributeSyncData(chainIdOrigin, encodedDataWithExtIdAndMasterOrigin); 
            }

            emit SyncDataMessage(encodedData);        
        } else if (chainIdOrigin == chainIdMaster) {
            _storeData(encodedData);
        }

        latestSyncTimestamp = latestSyncTime;
    }

    /*
     * Encodes the data for syncing data with an extension ID.
     * This is used to standarize the format of messages being sent for synchronization.
     */
    function _encodeSyncDataWithExtId(bytes memory encodedDataWithMasterOrigin) 
        internal 
        pure 
        returns (
            bytes memory encodedDataWithExtId
        ) 
    {
        bytes memory encodedData = abi.encode(syncMessageId, encodedDataWithMasterOrigin);
        return encodedData;
    }

    /*
     * Decodes the data for syncing data, extracting the origin chain ID, content data, and sync time.
     * This function is crucial for understanding the context and content of incoming sync data message.
     */
    function _decodeSyncDataWithExtId(bytes memory encodedDataWithExtId) 
        internal 
        pure 
        returns (
            uint64 chainIdOrigin, 
            bytes memory encodedData, 
            uint256 latestSyncTime
        ) 
    {
        (, bytes memory syncData) = abi.decode(encodedDataWithExtId, (bytes4, bytes));
        (chainIdOrigin, encodedData, latestSyncTime) = abi.decode(syncData, (uint64, bytes, uint256));
    }

    /*
     * Forwards the encodedData directly to the master chain for processing.
     * This is a key function in ensuring that the master chain receives all relevant data for synchronization.
     */
    function _sendToMaster(bytes memory encodedData) private returns (bytes32 messageId) {        
        CrossChainMetadataAddress memory _metadataChainMaster = getConfigFromNetwork(chainIdMaster);
        messageId = _sendMessage(chainIdMaster, _metadataChainMaster.crossChainApp, encodedData);
   }

    /*
     * Internal function for applications using this abstract contract to sync data across all contracts in all chains.
     * It packages the data and initiates the synchronization process.
     */
    function _syncData(bytes memory encodedData) internal {
        bytes memory syncData = abi.encode(chainIdThis, encodedData, block.timestamp);
        bytes memory encodedDataWithExtensionId = abi.encode(syncMessageId, syncData);
        _sendToMasterOrUpdate(encodedDataWithExtensionId );
    }

    /*
     * Called when the contract receives a encodedData for data storage.
     * This is where the implementation for data storage should be defined.
     */
    function _storeData(bytes memory encodedData) internal virtual;

    /*
     * Properly distributes data to all chains, excluding the origin chain.
     * This function ensures data consistency and availability across the network.
     */
    function _distributeSyncData(uint64 excludedChain, bytes memory data) private {
        CrossChainMetadataAddress[6] memory _metadatas = getAllNetworks(); 

        // always exclude sepolia and excludedChain (origin) for duplication while storing data
        for(uint8 i = 1; i < _metadatas.length; i++) {
            if (_metadatas[i].chainIdSelector != excludedChain) {
                _sendMessage(_metadatas[i].chainIdSelector, _metadatas[i].crossChainApp, data);    
            }
        }
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
    }

    /*
     * Handles CCIP receive logic, managing cross-chain message passing and execution.
     */
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

    /**
     * @dev Checks whether is CRC1Syncable
     */
    function supportsExtInterface(bytes4 interfaceId) public view virtual override(CRC1) returns (bool) {
        return
            super.supportsInterface(interfaceId) ||
            interfaceId == 0x44617461;
    }

}
