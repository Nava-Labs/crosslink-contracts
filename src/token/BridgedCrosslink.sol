// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {TokenProxy_Destination , ERC20} from "../proxy/TokenProxy_Destination.sol";

/*
 * Contract example for deploying a token across multiple chains.
 * Demonstrate how a token can be deployed and managed across different chains
 * in a network powered by the our Chainlink App library and Token Proxy standarization.
 */
contract BridgedCrosslink is ERC20, TokenProxy_Destination {
    constructor(
        string memory name, 
        string memory symbol, 
        address router,
        uint64 chainIdThis
    ) ERC20(name, symbol) TokenProxy_Destination(router,chainIdThis) {}
}