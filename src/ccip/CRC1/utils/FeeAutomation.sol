// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";

struct RegistrationParams {
    string name; // Name of the registered Upkeep
    bytes encryptedEmail; // can be blank
    address upkeepContract; // address of your automation contract
    uint32 gasLimit; // The maximum gas limit that will be used for your txns.
    address adminAddress; // The address that will have admin rights for this upkeep
    uint8 triggerType; //  1 is Log trigger upkeep
    bytes checkData; // checkData is a static input that you can specify now which will be sent into your checkUpkeep or checkLog
    bytes triggerConfig; // The Log configuration for your upkeep
    bytes offchainConfig; // Leave as 0x
    uint96 amount; // Amount that will be Transfered into Upkeep
}

// Encode this struct for triggerConfig
struct LogTriggerConfig {
 address contractAddress; // must have address that will be emitting the log
  uint8 filterSelector; // must have filtserSelector, denoting which topics apply to filter ex 000, 101, 111...only last 3 bits apply
  bytes32 topic0; // must have signature of the emitted event
  bytes32 topic1; // optional filter on indexed topic 1
  bytes32 topic2; // optional filter on indexed topic 2
  bytes32 topic3; // optional filter on indexed topic 3
}

struct Log {
    uint256 index; // Index of the log in the block
    uint256 timestamp; // Timestamp of the block containing the log
    bytes32 txHash; // Hash of the transaction containing the log
    uint256 blockNumber; // Number of the block containing the log
    bytes32 blockHash; // Hash of the block containing the log
    address source; // Address of the contract that emitted the log
    bytes32[] topics; // Indexed topics of the log
    bytes data; // Data of the log
}

error FailedToRegisterAutomation(uint256);

interface AutomationRegistrarInterface {
    function registerUpkeep(RegistrationParams calldata requestParams) external returns (uint256);
}

interface ILogAutomation {
    function checkLog(
        Log calldata log,
        bytes memory checkData
    ) external returns (bool upkeepNeeded, bytes memory performData);

    function performUpkeep(bytes calldata performData) external;
}


/*
 * Contract extension serving as a Fee Automation for CRC1.
 * This contract is responsible for handling CRC1 Fee.
 */
contract FeeAutomation is OwnerIsCreator{

    address immutable i_link;
    address immutable i_registrar;

    // Initial Value of minimum and topUp Amount
    uint256 public minimumLinkThreshold = 5 ether;
    uint256 public topupLinkAmount = 5 ether;

    event SuccessFeeTopUp(uint256 timestamp);

    constructor(
        address link,
        address automationRegistrar
    ) {
        i_link = link;
        i_registrar = automationRegistrar;
    }

    // =============================================================
    //               Setter Fee Threshold & top up link
    // =============================================================

    function setFeeMinimumAndTopUp(
        uint256 _minimumLinkThreshold, 
        uint256 _topupLinkAmount
    ) external onlyOwner{
        minimumLinkThreshold = _minimumLinkThreshold;
        topupLinkAmount = _topupLinkAmount;
    }

    // =============================================================
    //                      Register Automation
    // =============================================================

    /*
    * Register Automation with log Trigger
    */
    function registerFeeAutomation(uint96 upkeepInitialAmount) external onlyOwner {
        // Approve Registrar
        LinkTokenInterface(i_link).approve(i_registrar, type(uint256).max);

        // For upkeeps with triggers using emitted logs, the following parameters are needed:
        LogTriggerConfig memory logTriggerConfig = LogTriggerConfig({
            contractAddress : address(this), // Contract emitting logs
            filterSelector : 0, // Because there is no topic / Indexed
            topic0 : keccak256("MessageSent(bytes32,bytes)"), // Emit MessageSent(bytes32,bytes)
            topic1 : 0x0000000000000000000000000000000000000000000000000000000000000000, // did not emit indexer
            topic2 : 0x0000000000000000000000000000000000000000000000000000000000000000,
            topic3 : 0x0000000000000000000000000000000000000000000000000000000000000000
        });

        // For Registration into Automation
        RegistrationParams memory registrationParams = RegistrationParams({
            name : "CRC1-Fee-Automation", // Standarized name
            encryptedEmail : "",
            upkeepContract : address(this),
            gasLimit : 1000000,
            adminAddress : msg.sender,
            triggerType : 1,
            checkData : "",
            triggerConfig : abi.encode(logTriggerConfig),
            offchainConfig :"",
            amount : upkeepInitialAmount
        });

        uint256 upkeepId = AutomationRegistrarInterface(i_registrar).registerUpkeep(registrationParams);

        if(upkeepId == 0){
            revert FailedToRegisterAutomation(upkeepId);
        }
    }
    
    // =============================================================
    //                      Fee Automation Run
    // =============================================================

    /*
    * Function that will be hit when Log get Triggered
    * This contract is responsible for performing upkeep if returns True
    * Check Balance of token link in this Contract
    * If it's below minimumLinkThreshold then return true
    */
    function checkLog(
        Log calldata log,
        bytes memory checkData
    ) external view returns (bool upkeepNeeded, bytes memory performData) {
        uint256 balanceOfLink = LinkTokenInterface(i_link).balanceOf(address(this));

        if(balanceOfLink <= minimumLinkThreshold){
            upkeepNeeded = true;
        }else{
            upkeepNeeded = false;
        }

       performData = abi.encode(owner(),address(this),topupLinkAmount);
    }

    /*
    * Run only checkLog response true
    * Transfer link into this address in accordance to topupLinkAmount
    */
    function performUpkeep(bytes calldata performData) external {
        (address fromOwner, address toAddressThis, uint256 _topupLinkAmount) = abi.decode(performData,(address,address,uint256));

        LinkTokenInterface(i_link).transferFrom(fromOwner, toAddressThis, _topupLinkAmount);

        emit SuccessFeeTopUp(block.timestamp);
    }
}
