# CRC1 & CRC20

## Overview
This repository presents an extensive framework designed for the development of cross-chain applications and the standardization of tokens, utilizing the capabilities of Chainlink CCIP. It includes several key components: CRC1, CRC1Syncable, CRC20 and FeeAutomation.

## Components
### CRC1
- A foundational contract for building cross-chain applications using Chainlink CCIP.
- Enables functionalities like message sending, receiving, and processing across chains.
- Supports Multihop functionality across all chains and Message Bundling for bulk operations by default.

  **Key Functions:**
  - `_executeAndForwardMessage(uint64[] memory bestRoutes, bytes[] memory encodedAppMessage)`: Handles the execution and forwarding of messages across chains. Best Routes parameters should be populated by Chainlink chainIdSelector (**chain by chain**). Pass the encoded message to this function to execute logic app. <br /> 
    <br />
    `e.g FUJI -> BASE GOERLI -> OP GOERLI` <br />
    `bestRoutes` supposed to be `[14767482510784806043,5790810961207155433,2664363617261496610]` <br />
    <br />
    `e.g SEPOLIA -> MUMBAI -> BASE GOERLI -> BSC TESTNET` <br />
     `bestRoutes` supposed to be `[16015286601757825753,12532609583862916517,5790810961207155433,13264668187771770619]` <br />
    <br />
  - `_executeAppMessage(bytes[] memory encodedAppMessage)`: Processes application-specific messages.

  **Notes:** `encodedAppMessage` must be decodable in `executeAppMessage`.

### CRC1Syncable
- An extension of CRC1, designed for applications that require consistent states across contracts on various chains.
- Manages cross-chain data synchronization and state harmonization.

  **Key Functions:**
  - `_syncData(bytes memory encodedData)`: Synchronizes data across chains.
  - `_storeData(bytes memory encodedData)`: Processes application-specific data (how data stored).
  - `_sendToMasterOrUpdate(bytes memory encodedDataWithExtensionId)`: Sends data to the master chain and synchronizes the data across chains.

  **Notes:** `encodedData` must be decodable in `storeData`.

### Trustable
- Provides a security layer for CRC1, ensuring secure cross-chain operations.

### CRC20 (Source and Destination)
- A framework for ERC20 tokens to operate across multiple chains, integrating with the CRC1 contract.
- Split into CRC20Source and CRC20Destination for token wrapping and deployment on various chains.

  **CRC20Source Key Functions:**
  - `lockAndMint`: Locks tokens on the source chain and mints corresponding tokens on the destination chain.
  - `_executeAppMessage`: Overridden to handle messages specific to CRC20Source.

  **CRC20Destination Key Functions:**
  - `burnAndMintOrUnlock`: Burns tokens on the destination chain and mints or unlocks corresponding tokens on the target chain.
  - `_executeAppMessage`: Overridden to handle messages specific to CRC20Destination.

### FeeAutomation 
- Utilize chainlink automation for mantain fee allocation in cross-chain app.
- Avoiding mantaining LINK balance manually.
- Action triggered everytime cross-chain app send CCIP message, emitted `MessageSent(bytes32,bytes)` event.

## Usage
### Deploying a Cross-Chain Application
- Base your application on CRC1.
- Extend with CRC1Syncable for synchronized state applications.

### Making an ERC20 Token Cross-Chain
- Deploy CRC20Source on the chain where the original ERC20 token exists.
- Implement CRC20Destination on destination chains to enable the token's cross-chain functionality.

### Utilize FeeAutomation 
- Import FeeAutomation
- Hit `registerFeeAutomation`

## Testnet Implementation
### NFT Marketplace
Sepolia: `0xd88b22CBB849232A93e5BC6c61D4195709C39dE4` <br />
OP Goerli: `0xEDF48f9A4cC17db3C22eAAAe88cE1126C0cA0587`<br />
Fuji: `0x1dEACeF410005b6c670F35cBFf0Da98a6D606e4A`<br />
Mumbai: `0xBEca54a2125EBf272D65ea4e03A2C9F030D2b619`<br />
Base Goerli: `0x4A1e43392E68239A918F675D0826AB294923b5C3`<br />
Chapel: `0x40D969600d2B2a884AB80747C8448df57F412f47`<br />

### Token
Dummy ETH (Sepolia): `0x20AF34a33637C2c1671E071Dba89FB68f4403334`<br />
CRC20Source (Sepolia): `0xd4685C3E3Eb5fC23338Ef1F0Cce65Af4511B8A6F`<br />
OP Goerli: `0x389D25C259885A4FFa4f51B4938310b9390fC3a1`<br />
Fuji: `0xb165891E7b98De56E96662981a8966c357477d5c`<br />
Mumbai: `0xAB299f4012524cC191B17908E9161b05Bb1088DE`<br />
Base Goerli: `0x162f2E18935394CA0A1643ae9371A351d6451d2f`<br />
Chapel: `0x5794dD4b2B1C7f11D5E22095B69a772b970FcAe1`<br />

## Other cool things that we build in Constellation 2023 🛠️
- **[OpenCCIP SDK](https://github.com/Nava-Labs/openccip-sdk) - Dijkstra's Algorithm**: 
  - Following the principle of Dijkstra's Shortest Path Algorithm, we assigned "weight" to each possible direct lane supported by CCIP which is calculated based on each blockchain _Time-To-Finality_, _5-day average gas price_, and _Transaction per Second_.
  - With the assigned "weight", the best route can be found. To make things easy from the front end, we build this into an SDK, so the front end only needs to pass the "from" and "to" chains. The SDK will find the best possible routes, which then will be passed to the smart contract for the cross-chain transaction to be executed.
- **The Graph**:
  - Index data across all chains (thanks to **CRC1Syncable**), such as the details of listed NFTs in all chains and ease the process of showing data in the front end.

