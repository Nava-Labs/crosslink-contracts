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
       require(chainSelector.length == crossChainAppAddress.length);
       for (uint256 i = 0; i < chainSelector.length; i++) {
            _crossChainMetadataAddress[chainSelector[i]].crossChainApp = crossChainAppAddress[i];
        }
    }

    // add this function to your ccipReceive
    function _sendToMasterOrUpdate(
        bytes memory data
    ) internal {
        (uint64 _chainIdOrigin, bytes memory _data) = abi.decode(data, (uint64, bytes));

        if (chainIdThis != chainIdMaster && _chainIdOrigin != chainIdMaster) {
            _sendToMaster(data);
        }  else if (chainIdThis == chainIdMaster) {
            bytes memory encodedDataWithMasterOrigin = abi.encode(chainIdMaster, _data);
            _storeData(_data);
            _distributeProperly(_chainIdOrigin, encodedDataWithMasterOrigin); // exclude origin and self
        } else if (_chainIdOrigin == chainIdMaster) {
            _storeData(_data);
        }
    }

    function _sendToMaster(bytes memory data) private returns (bytes32 messageId) {        
        CrossChainMetadataAddress memory _metadataChainMaster = getConfigFromNetwork(chainIdMaster);
        messageId = _sendMessage(chainIdMaster, _metadataChainMaster.crossChainApp, data);
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

        emit SyncDataMessage(messageId, data);        
    }

    function _syncData(bytes memory data) internal {
        _sendToMasterOrUpdate(abi.encode(chainIdThis, data));
    }

    function _storeData(bytes memory data) internal virtual;


    function _distributeProperly(uint64 excludedChain, bytes memory data) private {
        CrossChainMetadataAddress[3] memory _metadatas = getAllNetworks(); 

        // always exclude sepolia for duplication while storing data
        for(uint8 i = 1; i < _metadatas.length; i++) {
            if (_metadatas[i].chainIdSelector != excludedChain) {
                _sendMessage(_metadatas[i].chainIdSelector, _metadatas[i].crossChainApp, data);    
            }
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
