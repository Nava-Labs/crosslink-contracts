// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {TokenProxy_Destination , ERC20} from "../proxy/TokenProxy_Destination.sol";

contract BridgedCrosslink is ERC20, TokenProxy_Destination {
    constructor(
        string memory name, 
        string memory symbol, 
        address router,
        uint64 chainIdThis
    ) ERC20(name, symbol) TokenProxy_Destination(router,chainIdThis) {}
}