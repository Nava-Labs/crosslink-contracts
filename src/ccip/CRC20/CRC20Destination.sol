// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {IERC20, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {CRC1} from "../CRC1/CRC1.sol";
import {ICRC20Destination} from "./interfaces/ICRC20Destination.sol";

error UnauthorizedChainSelector();

/**
 * @dev `CRC20Destination` is an extension of {ERC20} designed to simplify the process of deploying and managing tokens across multiple blockchain networks. It is part of a cross-chain token management framework that integrates with the CRC1 contract.
 * 
 * This contract allows for easy creation of cross-chain tokens by inheriting `CRC20Destination`. Developers can deploy a token on any chain by simply extending this contract, making the token instantly compatible with other chains in the network.
 * 
 * The integration of `CRC20Destination` with CRC1 provides robust security features, ensuring safe and secure token operations across multiple blockchain ecosystems.
 */
abstract contract CRC20Destination is CRC1, ICRC20Destination, ERC20 {    

    /**
     * @dev Emitted when ERC20 is unlocked or minted
     */
    event Unlock(address indexed to, uint256 indexed amount);

    constructor(string memory name, string memory symbol, address _router, uint64 _chainIdThis) 
    ERC20(name, symbol) 
    CRC1(_chainIdThis, _router) {}

    receive() external payable {}

    function burnAndMintOrUnlock(uint64[] memory bestRoutes ,address tokenReceiver, uint256 amount) external virtual {
        // burn
        _burn(msg.sender, amount);

        // encode tokenReceiver & amount
        bytes[] memory encodedMessage = new bytes[](1);
        encodedMessage[0] = abi.encode(tokenReceiver,amount);

        /*
         * Executes and forwards the message across chains.
         * It handles the routing and execution of encoded messages, in multi-hop scenarios.
         * In this case, it's used for triggering the minting of tokens on the destination chain.
         */
        _executeAndForwardMessage(bestRoutes, encodedMessage);

        emit Unlock(msg.sender, amount);
    }

    /*
     * Example implementation of the _executeAppMessage function from the CRC1 contracts.
     * This function demonstrates how you can override and implement custom logic for processing
     * received encoded messages. In this example, it decodes each message to extract a receiver
     * address and an amount, then mints tokens to that address and emits an event.
     */
    function _executeAppMessage(bytes[] memory encodedMessage) internal override {
        for(uint256 i = 0; i < encodedMessage.length; i++){
            (address tokenReceiver , uint256 amount) = abi.decode(encodedMessage[i],(address,uint256));

            _mint(tokenReceiver, amount);

            emit Unlock(tokenReceiver, amount);
        }
    }
}