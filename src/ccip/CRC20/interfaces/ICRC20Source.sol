// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ICRC20Source {
    function lockAndMint(uint64[] memory bestRoutes ,address tokenReceiver, uint256 amount) external;
}