# ERC20 Rewards to NFT Holder Distribution System

This project provides a smart contract-based solution for distributing ERC20 rewards to NFT holders. The system includes various contracts and an off-chain service for managing NFT ownership snapshots and reward distributions.

## Table of Contents

- [Overview](#overview)
- [Project Structure](#project-structure)
- [Contract Solutions](#contract-solutions)
- [Off-Chain Snapshot Service](#off-chain-snapshot-service)
- [Understanding `snapshot.js`](#understanding-snapshotjs)
- [Understanding `autoclainchainlink.sol`](#understanding-autoclainchainlinksol)
- [Prerequisites](#prerequisites)
- [Environment Variables](#environment-variables)
- [Smart Contract Deployment](#smart-contract-deployment)
- [Running the Snapshot Service](#running-the-snapshot-service)
- [Setting Up Chainlink Keepers](#setting-up-chainlink-keepers)
- [Testing and Deployment](#testing-and-deployment)
- [Security Considerations](#security-considerations)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)
- [Next Steps](#next-steps)

## Overview

This project automates the distribution of ERC20 rewards to NFT holders by managing NFT ownership data and facilitating the distribution process based on that data. The project supports both manual and automated reward distribution mechanisms.

## Project Structure

- **`.env.local`**: Stores environment variables like private keys, Infura project ID, contract addresses, etc.
- **`autoclaim.sol`**: Contract for distributing rewards based on NFT ownership using Merkle proofs.
- **`autoclaimsnap.sol`**: Contract for managing NFT ownership snapshots and allowing users to claim rewards based on those snapshots.
- **`autoclainchainlink.sol`**: Contract for fully automated reward distribution using Chainlink Keepers.
- **`rewardContractABI.json`**: ABI (Application Binary Interface) file for the reward distribution contracts.
- **`snapshot.js`**: Off-chain service script that takes snapshots of NFT ownership and updates the contract with the new Merkle root.

## Contract Solutions

### 1. Merkle Tree-Based Reward Claiming (`autoclaim.sol`)

- **Description**: Users can claim rewards by submitting a valid Merkle proof. This contract allows for verifying ownership through the Merkle tree.
- **Manual Trigger**: Users must call `claimReward` with the appropriate proof.

### 2. Snapshot-Based Reward Distribution (`autoclaimsnap.sol`)

- **Description**: The contract allows the owner to distribute rewards automatically to NFT holders by calling `distributeRewards`, based on a specific range of NFTs.
- **Manual Trigger**: The owner must manually call `distributeRewards`.

### 3. Fully Automated Reward Distribution (`autoclainchainlink.sol`)

- **Description**: This contract integrates with Chainlink Keepers to automate the reward distribution process without manual intervention. It checks every 24 hours if the conditions are met for distribution and executes the function if they are.
- **Automation**: The distribution is fully automated and does not require manual intervention.

## Off-Chain Snapshot Service

The `snapshot.js` file is an off-chain service that automates the process of taking NFT ownership snapshots and updating the Merkle root on-chain.

### 1. Install Node.js Dependencies

Before running the service, install the required dependencies:

```bash
npm install ethers merkletreejs keccak256 dotenv winston
```

### 2. Run the Snapshot Service

```bash
node snapshot.js
```

This script will:
- Fetch all NFT ownership data.
- Generate a Merkle tree from the ownership data.
- Update the contract with the new Merkle root.

## Understanding `snapshot.js`

The `snapshot.js` script is responsible for automating the process of taking snapshots of NFT ownership and updating the Merkle root in the smart contract. Here’s a breakdown of its key components:

1. **Environment Variables**: The script uses environment variables to configure the connection to the Ethereum network and the contract addresses. Ensure that your `.env.local` file is correctly set up with the required values.

2. **Logging**: The script uses the `winston` library for logging, which helps track the execution flow and any errors that occur during the process.

3. **Retry Logic**: The `retryOperation` function implements a retry mechanism with exponential backoff for operations that may fail due to network issues, ensuring robustness.

4. **Batch Fetching**: The `fetchNFTOwnersBatch` function retrieves NFT owners in batches to avoid timeouts. This is crucial for contracts with a large number of NFTs.

5. **Merkle Tree Generation**: The `generateMerkleTree` function creates a Merkle tree from the fetched NFT ownership data, which is then used to verify claims.

6. **Updating the Merkle Root**: The `updateMerkleRoot` function estimates gas for the transaction and updates the Merkle root in the smart contract.

7. **Main Function**: The `snapshotAndUpdate` function orchestrates the entire process, from fetching NFT owners to updating the contract.

## Understanding `autoclainchainlink.sol`

The `autoclainchainlink.sol` contract automates the reward distribution process using Chainlink Keepers. Here’s a detailed explanation of its components:

### Contract Initialization

- **Constructor Parameters**:
  - `address _nftContractAddress`: The address of the deployed ERC721 NFT contract.
  - `address _rewardTokenAddress`: The address of the deployed ERC20 reward token contract.
  - `uint256 _rewardPerNFT`: The amount of reward each NFT holder will receive.
  - `uint256 _reservedTokens`: The initial amount of tokens reserved for rewards.

### Key Functions

1. **checkUpkeep**: 
   - This function is called by Chainlink Keepers to check if the contract needs upkeep. It returns `true` if the last distribution was more than 24 hours ago and the contract is not paused.

2. **performUpkeep**: 
   - This function is executed by Chainlink Keepers when `checkUpkeep` returns `true`. It calls the `distributeRewards` function to distribute rewards to NFT holders.

3. **distributeRewards**: 
   - This internal function distributes rewards to all NFT holders. It checks the total supply of NFTs, validates token existence, and transfers the reward tokens to each owner. It also updates the last distribution timestamp and deducts the distributed tokens from the reserved pool.

### Owner Functions

- **addReservedTokens**: Allows the owner to add more tokens to the reserved pool for future distributions.
- **emergencyWithdraw**: Allows the owner to withdraw remaining reward tokens from the contract in case of an emergency.
- **pauseDistribution**: Allows the owner to pause the distribution process in case of an emergency.
- **resumeDistribution**: Allows the owner to resume the distribution process after it has been paused.

## Prerequisites

Before you begin, ensure you have the following installed:

1. **Node.js** (>= v14.x)
   - [Download Node.js](https://nodejs.org/en/download/)
2. **Solidity** (>= 0.8.0)
   - Solidity compiler is typically built into Ethereum development tools like **Hardhat** or **Truffle**.
3. **Infura or Alchemy Account**:
   - Sign up for Infura [here](https://infura.io/) to get an API key for interacting with the Ethereum blockchain.
4. **Metamask Wallet**:
   - You'll need a wallet with sufficient ETH for deploying the contracts and running transactions.

## Environment Variables

Create a `.env.local` file in the root directory of the project. It should contain the following:

```ini
INFURA_PROJECT_ID=your-infura-project-id  # Infura project ID for Ethereum connection
PRIVATE_KEY=your-private-key              # Wallet private key for deploying contracts and sending transactions
CONTRACT_ADDRESS=your-reward-contract-address    # Address of the deployed reward distribution contract
NFT_CONTRACT_ADDRESS=your-nft-contract-address # Address of the deployed NFT contract
```

**Note**: Never expose your private key publicly. Use secure vault solutions (AWS Secrets Manager, Azure Key Vault) for production environments.

## Smart Contract Deployment

### 1. Compile and Deploy the Contracts

If you are using **Hardhat** or **Truffle** for contract deployment, ensure the dependencies are installed, and follow these steps:

1. **Install dependencies**:

   ```bash
   npm install
   ```

2. **Compile the contracts**:

   ```bash
   npx hardhat compile  # or truffle compile
   ```

3. **Deploy the contracts**:

   For **Hardhat**:

   ```bash
   npx hardhat run scripts/deploy.js --network <network>
   ```

   Replace `<network>` with the network you're deploying to (e.g., `rinkeby`, `goerli`, or `mainnet`).

4. **Update Contract Address**:
   - Once the contracts are deployed, update the `CONTRACT_ADDRESS` and `NFT_CONTRACT_ADDRESS` in the `.env.local` file.

### 2. Verify the Contracts

Once the contracts are deployed, you can verify them using **Etherscan** if you're deploying to Ethereum mainnet or a testnet:

```bash
npx hardhat verify --network <network> <contract-address>
```

## Running the Snapshot Service

The `snapshot.js` file is the off-chain service that automates the process of taking NFT ownership snapshots and updating the Merkle root on-chain.

### 1. Install Node.js Dependencies

Before running the service, install the required dependencies:

```bash
npm install ethers merkletreejs keccak256 dotenv winston
```

### 2. Run the Snapshot Service

```bash
node snapshot.js
```

This script will:
- Fetch all NFT ownership data.
- Generate a Merkle tree from the ownership data.
- Update the contract with the new Merkle root.

### 3. Automate the Snapshot Service

You can automate this script to run at specific intervals (e.g., every 24 hours) using **cron jobs** or **Task Scheduler**. For example, to run the script every 24 hours using cron:

1. Open crontab:

   ```bash
   crontab -e
   ```

2. Add the following line to schedule the task:

   ```bash
   0 0 * * * /usr/bin/node /path/to/snapshot.js >> /path/to/logs/snapshot.log 2>&1
   ```

This will run the script every day at midnight and log the output to `snapshot.log`.

## Setting Up Chainlink Keepers

To fully automate the reward distribution process using Chainlink Keepers, follow these steps:

### 1. Deploy the Contract on a Supported Network

Ensure that your `autoclainchainlink.sol` contract is deployed on a network that supports Chainlink Keepers (e.g., Ethereum mainnet, Goerli).

### 2. Register Your Contract with Chainlink Keepers

1. **Visit the Chainlink Keepers Registry**: Go to the [Chainlink Keepers Registry](https://keepers.chain.link/) and connect your wallet.

2. **Register Your Contract**:
   - In the interface, select your deployed contract and specify the `checkUpkeep` and `performUpkeep` functions.
   - Define the conditions under which you want the Keepers to trigger the `performUpkeep()` function (e.g., every 24 hours).
   - Complete the registration process by providing the necessary details and paying any associated fees.

3. **Verify Registration**: Once your contract is registered, you can verify its status on the Chainlink Keepers Registry. 

### 3. Funding Your Contract

Make sure your contract has enough LINK tokens to fund the Chainlink Keepers service. You can purchase LINK tokens on exchanges and transfer them to your deployed contract address.

### 4. Monitor and Maintain

After setting up Chainlink Keepers:
- Monitor your contract to ensure it's functioning as expected.
- Check logs and keep an eye on gas costs to ensure efficient execution.

## Testing and Deployment

### 1. Test on a Testnet

Before deploying to the Ethereum mainnet, it is important to test on a testnet like **Goerli** or **Rinkeby**.

1. Update the `.env.local` file to use your testnet contract addresses.
2. Deploy the contracts and test the following:
   - Ensure the off-chain service correctly takes ownership snapshots.
   - Ensure the Merkle proofs are valid on-chain and users can claim rewards.
   - Verify gas costs for various transactions (Merkle root updates, reward claims).

### 2. Mainnet Deployment

Once testing is complete, repeat the deployment steps for the Ethereum mainnet and update the `.env.local` file with the mainnet addresses.

## Security Considerations

1. **Private Key Management**:
   - Do not hardcode your private key in the code. Store it in the `.env.local` file or use a secret management tool like **AWS Secrets Manager** or **Azure Key Vault**.

2. **Gas Management**:
   - Always estimate gas costs before submitting transactions to ensure that the wallet has sufficient ETH for transactions, especially when interacting with the mainnet.

3. **Error Handling**:
   - Ensure the `snapshot.js` service has robust error handling with retries for network issues and transaction failures.

4. **Auditing**:
   - Before deploying to mainnet, consider getting the smart contracts audited by a third-party security auditor to ensure the contract's integrity.

## Troubleshooting

- **Common Issues**:
  - If you encounter issues with transactions failing, check the gas limit and ensure your wallet has enough ETH.
  - Ensure that the NFT contract address and reward contract address are correctly set in the `.env.local` file.
  - If the snapshot service fails, check the logs for specific error messages.

- **Debugging Tips**:
  - Use console logs in `snapshot.js` to trace the execution flow and identify where issues may arise.
  - Verify that the NFT contract is deployed and accessible before running the snapshot service.

## Contributing

Contributions are welcome! If you would like to contribute to this project, please follow these steps:

1. Fork the repository.
2. Create a new branch (`git checkout -b feature/YourFeature`).
3. Make your changes and commit them (`git commit -m 'Add some feature'`).
4. Push to the branch (`git push origin feature/YourFeature`).
5. Open a pull request.

## License

This project is licensed under the **MIT License**.

## Contact

If you have any questions, feel free to reach out:

- **Twitter**: [@cris_vond]

## Next Steps

1. Thoroughly test the deployment on testnets.
2. Implement secure key management for production.
3. Ensure that the Merkle tree snapshot service runs automatically using cron jobs or any scheduling service.

---

Feel free to explore the code and modify the project according to your needs.
