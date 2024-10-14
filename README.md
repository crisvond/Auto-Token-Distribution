
# ERC20 rewards to NFT holder Distribution System

This project contains a smart contract-based solution to distribute ERC20 rewards to NFT holders. The system includes different contracts and an off-chain service for managing NFT ownership snapshots and reward distributions.

## Table of Contents

- [Overview](#overview)
- [Project Structure](#project-structure)
- [Contract Solutions](#contract-solutions)
- [Off-Chain Snapshot Service](#off-chain-snapshot-service)
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

This project automates the process of distributing ERC20 rewards to NFT holders by managing NFT ownership data and facilitating the distribution process based on that data. The project supports both manual and automated reward distribution mechanisms.

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

Feel free to explore the code and modify the project according to your needs. If you encounter any issues, don’t hesitate to ask for help!

---

This updated README now includes detailed instructions for setting up Chainlink Keepers, which automates the reward distribution process without manual intervention. Let me know if you need any further adjustments!
