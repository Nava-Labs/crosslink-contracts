// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {TrustedSender} from "./TrustedSender.sol";
import {MultiHop} from "../../lib/multihop/Multihop.sol";

error UnauthorizedChainSelector();

/**
 * @dev Extension of {ERC20} that properly manage token accross chain
 * via Chainlink CCIP.
 * recognized off-chain (via event analysis).
 */
contract TokenProxy_Source is CCIPReceiver, TrustedSender, Multihop {    

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

    // // Event emitted when a message is sent to another chain.
    // event MessageSent(
    //     bytes32 indexed messageId, // The unique ID of the message.
    //     uint64 indexed destinationChainSelector, // The chain selector of the destination chain.
    //     address receiver, // The address of the receiver on the destination chain.
    //     bytes data, // The message being sent.
    //     uint256 fees // The fees paid for sending the message.
    // );

    // // Event emitted when a message is received from another chain.
    // event MessageReceived(
    //     bytes32 indexed messageId, // The unique ID of the message.
    //     uint64 indexed sourceChainSelector, // The chain selector of the source chain.
    //     address sender, // The address of the sender from the source chain.
    //     bytes data // The message that was received.
    // );

    constructor(address _tokenAddress, address _router, uint64 _chainIdThis) CCIPReceiver(_router) MultiHop(_chainIdThis){
        tokenAddress = _tokenAddress;
    }

    receive() external payable {}

    function lockAndMint(string[] bestRoutes ,address tokenReceiver, uint256 amount) external virtual {
        // lock the real token
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);

        // Encode tokenReceiver & Amount
        bytes memory encodedMessage = abi.encode(tokenReceiver, amount);

        // ccip send for triggering mint in dest chain
        _executeOrForwardMessage(bestRoutes, encodedMessage);

        emit Lock(msg.sender, amount);
    }

    function _decodeAppMessage(bytes encodedMessage) internal override{
        // Trusted Sender check
        bytes memory trustedSender = trustedSenderLookup[sourceChainSelector];
        if (trustedSender.length == 0 ||
            keccak256(trustedSender) != keccak256(abi.encodePacked(sender, address(this)))
        ) {
            revert UnauthorizedChainSelector();
        }
        
        (address tokenReceiver , uint256 amount) = abi.decode(encodedMessage,(address,uint256));
        IERC20(tokenAddress).transfer(tokenReceiver,amount);

        emit Unlock(tokenReceiver, amount);

    }

    

    
}