// SPDX-License-Identifier: MIT
// TrustedSender Contracts v0.0.1
// Creator: Nava Labs

pragma solidity ^0.8.19;

import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {CCIPDirectory} from "./CCIPDirectory.sol";

/*
 * Security layer contract.
 * Purpose for secure the interaction between app across chains.
 */
contract Trustable is OwnerIsCreator, CCIPDirectory {

    /**
     * @dev Emitted when Trusted Sender is set
     */
    event SetTrustedSender(uint64[] _senderChainId, address[] _senderAddress);

    /**
     * Returns the trusted sender in specific chain
     */
    function getTrustedSender(uint64 _senderChainId) external view returns (address) {
       CrossChainMetadataAddress memory _metadataChainSender = getConfigFromNetwork(_senderChainId);
       return _metadataChainSender.crossChainApp;
    }

    /**
     * Updates the trusted sender in specific chain
     */
    function updateCrossChainApp(uint64[] memory chainSelector, address[] memory crossChainAppAddress) external override onlyOwner {
       for (uint256 i = 0; i < chainSelector.length; i++) {
            _crossChainMetadataAddress[chainSelector[i]].crossChainApp = crossChainAppAddress[i];
        }

        emit SetTrustedSender(chainSelector,crossChainAppAddress);
    }

    /**
     * Checks is sender is trusted or not
     */
    function isTrustedSender(uint64 _senderChainId , address senderMessage) internal view returns (bool) {
       CrossChainMetadataAddress memory _metadataChainSender = getConfigFromNetwork(_senderChainId);
       return _metadataChainSender.crossChainApp == senderMessage;
    }

 }