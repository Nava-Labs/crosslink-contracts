// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPDirectory} from "./CCIPDirectory.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/token/ERC20/IERC20.sol";

abstract contract DataProxy is OwnerIsCreator, CCIPDirectory {
    uint64 immutable public chainIdMaster;
    uint64 immutable public chainIdThis;

    event SyncDataMessage(bytes32 messageId, bytes data);

    constructor(uint64 _chainIdThis, uint64 _chainIdMaster) {
        CrossChainMetadataAddress memory _metadata = getConfigFromNetwork(_chainIdThis);

        chainIdThis = _chainIdThis;
        chainIdMaster = _chainIdMaster;
        
        LinkTokenInterface(_metadata.linkToken).approve(_metadata.ccipRouter, type(uint256).max);
    }

    function updateCrossChainApp(uint64[] memory chainSelector, address[] memory crossChainAppAddress) external override onlyOwner {
       for (uint256 i = 0; i < chainSelector.length; i++) {
            _crossChainMetadataAddress[chainSelector[i]].crossChainApp = crossChainAppAddress[i];
        }
    }

    // add this function to your ccipReceive
    function _sendToMasterOrUpdate(
        bytes memory data
    ) internal {
        (uint64 _chainIdOrigin, bytes memory encodedData) = abi.decode(data, (uint64, bytes));

        if (chainIdThis == chainIdMaster) {
            _storeData(data);
            _distributeToAll(data);
        } else if (_chainIdOrigin == chainIdMaster) {
            _storeData(data);
        } else {
            bytes memory encodedDataWithOrigin = abi.encode(chainIdMaster, encodedData);
            _sendToMaster(encodedDataWithOrigin);
        }
    }

    function _sendToMaster(bytes memory data) private returns (bytes32 messageId) {        
        CrossChainMetadataAddress memory _metadataChainMaster = getConfigFromNetwork(chainIdMaster);
        messageId = _sendMessage(_metadataChainMaster.crossChainApp, data);
   }

    function _sendMessage(address receiver, bytes memory data) internal returns (bytes32 messageId) {
        CrossChainMetadataAddress memory _metadataChainThis = getConfigFromNetwork(chainIdThis);

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: data,
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: "",
            feeToken: _metadataChainThis.linkToken
        });

        messageId = IRouterClient(_metadataChainThis.ccipRouter).ccipSend(
            chainIdMaster,
            message
        );

        emit SyncDataMessage(messageId, data);        
    }

    function _syncData(uint64 chainIdOrigin, bytes memory data) internal {
        _sendToMasterOrUpdate(abi.encode(chainIdOrigin, data));
    }

    function _storeData(bytes memory data) internal virtual;


    function _distributeToAll(bytes memory data) private {
        CrossChainMetadataAddress[5] memory _metadatas = getAllNetworks(); 

        for(uint8 i = 0; i < _metadatas.length; i++) {
            _sendMessage(_metadatas[i].crossChainApp, data);
        }
    }

    function withdrawToken(
        address beneficiary,
        address token
    ) public onlyOwner {
        uint256 amount = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(beneficiary, amount);
    }

}
