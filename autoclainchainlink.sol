// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/cryptography/MerkleProof.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address);
    function totalSupply() external view returns (uint256);
    function exists(uint256 tokenId) external view returns (bool); // Check if token exists
}

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract AutomatedNFTRewardDistributor is Ownable, ReentrancyGuard, AutomationCompatibleInterface {
    IERC721 public nftContract;            // ERC721 NFT Contract
    IERC20 public rewardToken;             // ERC20 Reward Token
    uint256 public rewardPerNFT;           // Reward per NFT
    uint256 public reservedTokens;         // Tokens reserved for rewards

    bool public paused;                    // Emergency pause flag
    uint256 public lastDistributionTime;   // Timestamp of the last distribution

    event MerkleRootUpdated(bytes32 newMerkleRoot);
    event RewardClaimed(address indexed user, uint256 amount);
    event ReservedTokensAdded(uint256 amount);
    event EmergencyPause(bool status);
    event EmergencyResume(bool status);
    event EmergencyWithdraw(address indexed owner, uint256 amount);
    event AutoRewardDistributed(address indexed user, uint256 amount);

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    constructor(
        address _nftContractAddress, 
        address _rewardTokenAddress, 
        uint256 _rewardPerNFT, 
        uint256 _reservedTokens
    ) {
        nftContract = IERC721(_nftContractAddress);
        rewardToken = IERC20(_rewardTokenAddress);
        rewardPerNFT = _rewardPerNFT;
        reservedTokens = _reservedTokens;
        paused = false;
        lastDistributionTime = block.timestamp; // Initialize to current time
    }

    // Check if upkeep is needed (Chainlink Keeper function)
    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory) {
        upkeepNeeded = (block.timestamp >= lastDistributionTime + 24 hours) && !paused;
    }

    // Perform the automated upkeep (Chainlink Keeper function)
    function performUpkeep(bytes calldata) external override whenNotPaused {
        require(block.timestamp >= lastDistributionTime + 24 hours, "Distribution can only occur once every 24 hours");
        distributeRewards();
    }

    // Automatically distribute rewards to NFT holders
    function distributeRewards() internal nonReentrant {
        uint256 totalNFTs = nftContract.totalSupply();
        require(totalNFTs > 0, "No NFTs found");

        uint256 totalReward = rewardPerNFT * totalNFTs; // Total reward for all NFTs
        require(reservedTokens >= totalReward, "Insufficient reserved tokens");
        require(rewardToken.balanceOf(address(this)) >= totalReward, "Insufficient contract balance");

        for (uint256 tokenId = 1; tokenId <= totalNFTs; tokenId++) {
            if (nftContract.exists(tokenId)) { // Validate token existence
                address nftOwner = nftContract.ownerOf(tokenId);
                rewardToken.transfer(nftOwner, rewardPerNFT); // Transfer rewards
                emit AutoRewardDistributed(nftOwner, rewardPerNFT); // Emit event
            }
        }

        reservedTokens -= totalReward;  // Deduct tokens from the reserved pool
        lastDistributionTime = block.timestamp;  // Update last distribution timestamp
    }

    // Admin function to add more tokens to the reserved pool for future distributions
    function addReservedTokens(uint256 amount) external onlyOwner {
        require(rewardToken.balanceOf(address(this)) >= reservedTokens + amount, "Token balance mismatch");
        reservedTokens += amount;
        emit ReservedTokensAdded(amount);
    }

    // Emergency function to withdraw remaining reward tokens in the contract
    function emergencyWithdraw(uint256 amount) external onlyOwner {
        require(amount <= rewardToken.balanceOf(address(this)), "Amount exceeds balance");
        rewardToken.transfer(owner(), amount);
        emit EmergencyWithdraw(owner(), amount);
    }

    // Allows the owner to pause the contract in case of emergency
    function pauseDistribution() external onlyOwner {
        paused = true;
        emit EmergencyPause(true);
    }

    // Allows the owner to resume the contract after being paused
    function resumeDistribution() external onlyOwner {
        paused = false;
        emit EmergencyResume(true);
    }

    // Fallback function to reject direct Ether payments
    receive() external payable {
        revert("Contract does not accept Ether");
    }
}
