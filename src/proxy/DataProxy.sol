// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {Withdraw} from "../utils/Withdraw.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {CCIPDirectory} from "./CCIPDirectory.sol";

abstract contract DataProxy is CCIPDirectory, Withdraw {

    uint64 immutable public chainIdMaster;
    uint64 immutable public chainIdThis;

    event MessageSent(bytes32 messageId, bytes data);

    constructor(uint64 _chainIdThis, uint64 _chainIdMaster) {
        CrossChainMetadataAddress memory _metadata = getConfigFromNetwork(_chainIdThis);

        chainIdThis = _chainIdThis;
        chainIdMaster = _chainIdMaster;
        
        LinkTokenInterface(_metadata.linkToken).approve(_metadata.ccipRouter, type(uint256).max);
    }

    receive() external payable {}   

    // add this function to your ccipReceive
    function _sendToMasterOrUpdate(
        bytes memory data
    ) private {
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
        CrossChainMetadataAddress memory _metadataChainThis = getConfigFromNetwork(chainIdThis);
        CrossChainMetadataAddress memory _metadataChainMaster = getConfigFromNetwork(chainIdMaster);

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(_metadataChainMaster.crossChainApp),
            data: data,
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: "",
            feeToken: _metadataChainThis.linkToken
        });

        
        messageId = IRouterClient(_metadataChainThis.ccipRouter).ccipSend(
            chainIdMaster,
            message
        );

        emit MessageSent(messageId, data);
    }

    function _syncData(uint64 chainIdOrigin, bytes memory data) internal {
        _sendToMasterOrUpdate(abi.encode(chainIdOrigin, data));
    }

    function _storeData(bytes memory data) internal virtual;


    function _distributeToAll(bytes memory data) private {
        
    }
}
