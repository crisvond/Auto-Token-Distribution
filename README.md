# AutoClaim Contract

This project contains a smart contract-based solution to distribute ERC20 rewards to NFT holders using a Merkle tree-based snapshot mechanism. The system includes:

- **Smart Contracts**: 
  - `autoclaim.sol`: Contract for distributing rewards without Merkle proofs.
  - `autoclaimsnap.sol`: Contract for distributing rewards based on Merkle proofs.
- **Off-chain Snapshot Service**:
  - `snapshot.js`: A Node.js script that periodically takes snapshots of the NFT ownership and updates the smart contract with the new Merkle root.
- **Environment Configurations**: `.env.local` for storing sensitive data.

## Table of Contents

- [Overview](#overview)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Environment Variables](#environment-variables)
- [Smart Contract Deployment](#smart-contract-deployment)
- [Running the Snapshot Service](#running-the-snapshot-service)
- [Testing and Deployment](#testing-and-deployment)
- [Security Considerations](#security-considerations)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)
- [Next Steps](#next-steps)

## Overview

This project automates the process of distributing ERC20 rewards to NFT holders by periodically taking snapshots of the ownership data and updating the contract with a Merkle root. NFT holders can then claim their rewards by submitting a Merkle proof.

## Project Structure

- **`.env.local`**: Stores environment variables like private keys, Infura project ID, contract addresses, etc.
- **`autoclaim.sol`**: Smart contract responsible for allowing users to claim rewards based on Merkle proofs.
- **`autoclaimsnap.sol`**: Contract for handling snapshot-related functionality.
- **`rewardContractABI.json`**: ABI (Application Binary Interface) file for the `autoclaim` contract.
- **`snapshot.js`**: Off-chain service script that takes snapshots of NFT ownership and updates the contract with the new Merkle root.

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
CONTRACT_ADDRESS=your-contract-address    # Address of the deployed reward distribution contract
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

