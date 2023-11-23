// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {IERC20 , ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ChainlinkApp} from "../chainlink-app/ChainlinkApp.sol";

error UnauthorizedChainSelector();

/**
 * @dev Extension of {ERC20} that properly manage token accross chain
 * via Chainlink CCIP.
 * recognized off-chain (via event analysis).
 */
contract TokenProxy_Source is ChainlinkApp {    

    address immutable public tokenAddress; 

    /**
     * @dev Emitted when ERC20 is locked
     */
    event Lock(address indexed initiator, uint256 indexed amount);

    /**
     * @dev Emitted when ERC20 is unlocked
     */
    event Unlock(address indexed to, uint256 indexed amount);

    // =============================================================
    //                            CCIP
    // =============================================================

    constructor(address _tokenAddress, address _router, uint64 _chainIdThis) ChainlinkApp(_chainIdThis, _router){
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
     * Example implementation of the _executeAppMessage function from the Chainlink app library.
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