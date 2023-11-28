# CRC1 & CRC20

## Overview
This repository presents an extensive framework designed for the development of cross-chain applications and the standardization of tokens, utilizing the capabilities of Chainlink CCIP. It includes several key components: CRC1, CRC1Syncable, and CRC20.

## Components
### CRC1
- A foundational contract for building cross-chain applications using Chainlink CCIP.
- Enables functionalities like message sending, receiving, and processing across chains.
- Supports Multihop functionality across all chains and Message Bundling for bulk operations by default.

  **Key Functions:**
  - `_executeAndForwardMessage(uint64[] memory bestRoutes, bytes[] memory encodedAppMessage)`: Handles the execution and forwarding of messages across chains. Best Routes parameters should be populated by Chainlink chainIdSelector. Pass the encoded message to this function to execute logic app.
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

## Usage
### Deploying a Cross-Chain Application
- Base your application on CRC1.
- Extend with CRC1Syncable for synchronized state applications.

### Making an ERC20 Token Cross-Chain
- Deploy CRC20Source on the chain where the original ERC20 token exists.
- Implement CRC20Destination on destination chains to enable the token's cross-chain functionality.

## Contributing
Contributions are welcome. Please submit pull requests or open issues for any enhancements or bug fixes.

