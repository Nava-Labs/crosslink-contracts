// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {CRC20Destination} from "ccip/CRC20/CRC20Destination.sol";

/*
 * Contract example for deploying a token across multiple chains.
 * Demonstrate how a token can be deployed and managed across different chains
 * using CRC1 and CRC20.
 */
contract CRC20Example is CRC20Destination {
    constructor(
        string memory name, 
        string memory symbol, 
        address router,
        uint64 chainIdThis,
        address link,
        address registrar
    ) CRC20Destination(name, symbol, router, chainIdThis, link, registrar) {}
}