// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Multihop, IRouterClient, Client, CCIPReceiver} from "../../lib/multihop/Multihop.sol";

error UnauthorizedChainSelector();

/**
 * @dev Extension of {ERC20} that properly manage token accross chain
 * via Chainlink CCIP.
 * recognized off-chain (via event analysis).
 */
abstract contract TokenProxy_Destination is Multihop, ERC20 {    

    /**
     * @dev Emitted when ERC20 is unlocked or minted
     */
    event Unlock(address indexed to, uint256 indexed amount);

    // =============================================================
    //                            CCIP
    // =============================================================

    constructor(address _router, uint64 _chainIdThis) Multihop(_chainIdThis, _router) {}

    receive() external payable {}

    function burnAndMintOrUnlock(uint64[] memory bestRoutes ,address tokenReceiver, uint256 amount) external virtual {
        // lock the real token
        _burn(msg.sender, amount);

        // Encode tokenReceiver & Amount
        bytes memory encodedMessage = abi.encode(tokenReceiver, amount);

        // ccip send for triggering mint in dest chain 
        _executeAndForwardMessage(bestRoutes, encodedMessage);

        emit Unlock(msg.sender, amount);
    }

    function _decodeAppMessage(bytes memory encodedMessage) internal override{
        (address tokenReceiver , uint256 amount) = abi.decode(encodedMessage,(address,uint256));
        _mint(tokenReceiver, amount);

        emit Unlock(tokenReceiver, amount);
    }
    

    
}