// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {CRC1} from "ccip/CRC1/CRC1.sol";
import {FeeAutomation} from "ccip/CRC1/utils/FeeAutomation.sol";
import {ICRC20Source} from "./interfaces/ICRC20Source.sol";

error UnauthorizedChainSelector();

/**
 * @dev `CRC20Source` is an extension of {ERC20} designed to simplify the process of deploying and managing tokens across
 * multiple blockchain networks. It is part of a cross-chain token management framework that integrates with the CRC1 contract.
 * 
 * `CRC20Source` is the initial contract to be deployed and acts as the central proxy for managing and initiating cross-chain token 
 * transactions. It is responsible wrapping the ERC20 and orchestrating token movements to other chains.
 * 
 * By utilizing CRC1, this contract enables seamless and secure token interoperability across multiple blockchains. Any ERC20 token 
 * can achieve cross-chain functionality by inheriting `CRC20Destination` on destination chains, with `CRC20Source` maintaining the 
 * ERC20.
 */
contract CRC20Source is CRC1, ICRC20Source, FeeAutomation {    

    address immutable public tokenAddress; 

    /**
     * @dev Emitted when ERC20 is locked
     */
    event Lock(address indexed initiator, uint256 indexed amount);

    /**
     * @dev Emitted when ERC20 is unlocked
     */
    event Unlock(address indexed to, uint256 indexed amount);

    constructor(address _tokenAddress, address _router, uint64 _chainIdThis, address _link, address _automationRegistrar) 
        CRC1(_chainIdThis, _router)
        FeeAutomation(_link, _automationRegistrar)
    {
        tokenAddress = _tokenAddress;
    }

    receive() external payable {}

    function lockAndMint(uint64[] memory bestRoutes, address tokenReceiver, uint256 amount) external virtual {
        // lock the real token
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);

        // Encode tokenReceiver & Amount
        bytes[] memory encodedMessage = new bytes[](1);
        encodedMessage[0] = abi.encode(tokenReceiver, amount);

        /*
         * Executes and forwards the message across chains.
         * It handles the routing and execution of encoded messages, in multi-hop scenarios.
         * In this case, it's used for triggering the minting of tokens on the destination chain.
         */        
        _executeAndForwardMessage(bestRoutes, encodedMessage);
        emit Lock(msg.sender, amount);
    }

    /*
     * Example implementation of the _executeAppMessage function from the CRC1 contracts.
     * This function demonstrates how you can override and implement custom logic for processing
     * received encoded messages. In this example, it decodes each message to extract a receiver
     * address and an amount, then unlocking the locked tokens to that address and emits an event.
     */
    function _executeAppMessage(bytes[] memory encodedMessage) internal override {
        for(uint256 i = 0; i < encodedMessage.length; i++){
            (address tokenReceiver , uint256 amount) = abi.decode(encodedMessage[i],(address,uint256));

            IERC20(tokenAddress).transfer(tokenReceiver,amount);
            
            emit Unlock(tokenReceiver, amount);
        }
    }
}
