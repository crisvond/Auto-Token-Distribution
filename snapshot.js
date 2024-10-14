require('dotenv').config();
const { ethers } = require('ethers');
const keccak256 = require('keccak256');
const { MerkleTree } = require('merkletreejs');
const winston = require('winston');  // Logging

// Load environment variables
const INFURA_PROJECT_ID = process.env.INFURA_PROJECT_ID;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const CONTRACT_ADDRESS = process.env.CONTRACT_ADDRESS;
const NFT_CONTRACT_ADDRESS = process.env.NFT_CONTRACT_ADDRESS;
const REWARD_CONTRACT_ABI = require('./rewardContractABI.json');

// Infura provider
const provider = new ethers.providers.InfuraProvider('mainnet', INFURA_PROJECT_ID);
const wallet = new ethers.Wallet(PRIVATE_KEY, provider);

// Load NFT Contract ABI
const nftContractABI = require('./nftContractABI.json');
const nftContract = new ethers.Contract(NFT_CONTRACT_ADDRESS, nftContractABI, provider);

// Load Reward Distribution Contract
const rewardContract = new ethers.Contract(CONTRACT_ADDRESS, REWARD_CONTRACT_ABI, wallet);

// Initialize logger with Winston
const logger = winston.createLogger({
    level: 'info',
    format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.json()
    ),
    transports: [
        new winston.transports.File({ filename: 'snapshot_service.log' }),
        new winston.transports.Console()
    ]
});

// Function to retry failed operations with exponential backoff
async function retryOperation(operation, retries = 3, delay = 1000) {
    for (let i = 0; i < retries; i++) {
        try {
            return await operation();
        } catch (error) {
            logger.error(`Attempt ${i + 1} failed: ${error.message}`);
            if (i < retries - 1) {
                await new Promise(res => setTimeout(res, delay));
                delay *= 2; // Exponential backoff
            } else {
                throw error;
            }
        }
    }
}

// Fetch NFT owners in batches to avoid timeouts
async function fetchNFTOwnersBatch(batchSize = 100) {
    const owners = [];
    const totalSupply = await retryOperation(() => nftContract.totalSupply());
    logger.info(`Total NFTs: ${totalSupply}`);

    for (let tokenId = 1; tokenId <= totalSupply; tokenId += batchSize) {
        const endTokenId = Math.min(tokenId + batchSize - 1, totalSupply);
        logger.info(`Fetching token IDs from ${tokenId} to ${endTokenId}`);
        
        const batchPromises = [];
        for (let id = tokenId; id <= endTokenId; id++) {
            batchPromises.push(retryOperation(() => nftContract.ownerOf(id)));
        }

        const batchOwners = await Promise.all(batchPromises);
        batchOwners.forEach((owner, idx) => {
            owners.push({ owner, tokenId: tokenId + idx });
        });

        logger.info(`Fetched owners for token IDs ${tokenId} to ${endTokenId}`);
    }

    return owners;
}

// Generate the Merkle Tree
function generateMerkleTree(owners) {
    const leaves = owners.map(({ owner, tokenId }) =>
        ethers.utils.keccak256(ethers.utils.defaultAbiCoder.encode(['address', 'uint256'], [owner, tokenId]))
    );
    const merkleTree = new MerkleTree(leaves, keccak256, { sortPairs: true });
    return merkleTree;
}

// Gas estimation and sending transaction to update Merkle root
async function updateMerkleRoot(merkleRoot) {
    const gasEstimate = await rewardContract.estimateGas.updateMerkleRoot(merkleRoot);
    logger.info(`Estimated gas: ${gasEstimate.toString()}`);

    const tx = await rewardContract.updateMerkleRoot(merkleRoot, { gasLimit: gasEstimate });
    logger.info(`Sent transaction: ${tx.hash}`);
    await tx.wait();  // Wait for confirmation
    logger.info(`Merkle root updated: ${merkleRoot}`);
}

// Main function to take a snapshot and update the contract
async function snapshotAndUpdate() {
    try {
        logger.info("Starting snapshot process...");

        // Fetch NFT owners in batches
        const owners = await fetchNFTOwnersBatch();
        logger.info(`Fetched ${owners.length} NFT owners`);

        // Generate Merkle tree
        const merkleTree = generateMerkleTree(owners);
        const merkleRoot = merkleTree.getHexRoot();
        logger.info(`Generated Merkle root: ${merkleRoot}`);

        // Estimate gas and update Merkle root
        await updateMerkleRoot(merkleRoot);

        logger.info("Snapshot and update completed successfully.");
    } catch (error) {
        logger.error(`Error during snapshot and update: ${error.message}`);
    }
}

// Run the snapshot process
snapshotAndUpdate();
