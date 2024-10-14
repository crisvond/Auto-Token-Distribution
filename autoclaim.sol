// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address);
    function totalSupply() external view returns (uint256);
    function exists(uint256 tokenId) external view returns (bool); // Check if token exists
}

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract NFTRewardDistributor is Ownable, ReentrancyGuard {

    IERC721 public nftContract;            // ERC721 NFT Contract
    IERC20 public rewardToken;             // ERC20 Reward Token
    uint256 public rewardPerNFT;           // Reward per NFT
    uint256 public lastDistribution;       // Timestamp of last distribution
    uint256 public distributionInterval;   // Time between distributions
    uint256 public reservedTokens;         // Tokens reserved for rewards
    uint256 public nftLimit;               // Max NFTs processed in one batch
    bool public paused;                    // Emergency pause flag

    event RewardDistributed(address indexed user, uint256 tokenId, uint256 amount);
    event RewardPerNFTUpdated(uint256 newRewardPerNFT);
    event DistributionIntervalUpdated(uint256 newInterval);
    event NFTLimitUpdated(uint256 newLimit);
    event EmergencyPause(bool status);
    event EmergencyResume(bool status);
    event ReservedTokensAdded(uint256 amount);
    event EmergencyWithdraw(address indexed owner, uint256 amount);

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    constructor(
        address _nftContractAddress, 
        address _rewardTokenAddress, 
        uint256 _rewardPerNFT, 
        uint256 _distributionInterval, 
        uint256 _reservedTokens, 
        uint256 _nftLimit
    ) {
        nftContract = IERC721(_nftContractAddress);
        rewardToken = IERC20(_rewardTokenAddress);
        rewardPerNFT = _rewardPerNFT;
        distributionInterval = _distributionInterval;
        reservedTokens = _reservedTokens;
        nftLimit = _nftLimit;
        paused = false;
        lastDistribution = block.timestamp; // Initialize last distribution timestamp
    }

    // Automatically distribute rewards to a range of NFTs in batches
    function distributeRewards(uint256 startTokenId, uint256 endTokenId) 
        external 
        onlyOwner 
        whenNotPaused 
        nonReentrant 
    {
        require(block.timestamp >= lastDistribution + distributionInterval, "Distribution interval has not passed");
        require(endTokenId >= startTokenId, "Invalid token range");

        uint256 totalNFTs = nftContract.totalSupply();
        require(totalNFTs > 0, "No NFTs found");
        require(endTokenId - startTokenId + 1 <= nftLimit, "Token range exceeds limit");

        uint256 totalReward = rewardPerNFT * (endTokenId - startTokenId + 1);
        require(reservedTokens >= totalReward, "Insufficient reserved tokens");
        require(rewardToken.balanceOf(address(this)) >= totalReward, "Insufficient contract balance");

        for (uint256 tokenId = startTokenId; tokenId <= endTokenId; tokenId++) {
            if (nftContract.exists(tokenId)) { // Validate token existence
                address nftOwner = nftContract.ownerOf(tokenId);
                rewardToken.transfer(nftOwner, rewardPerNFT); // Transfer rewards
                emit RewardDistributed(nftOwner, tokenId, rewardPerNFT); // Emit event
            }
        }

        reservedTokens -= totalReward;  // Deduct tokens from the reserved pool
        lastDistribution = block.timestamp;  // Update last distribution timestamp
    }

    // Admin function to update the reward per NFT
    function updateRewardPerNFT(uint256 newRewardPerNFT) external onlyOwner {
        rewardPerNFT = newRewardPerNFT;
        emit RewardPerNFTUpdated(newRewardPerNFT);
    }

    // Admin function to update the distribution interval
    function updateDistributionInterval(uint256 newInterval) external onlyOwner {
        distributionInterval = newInterval;
        emit DistributionIntervalUpdated(newInterval);
    }

    // Admin function to add more tokens to the reserved pool for future distributions
    function addReservedTokens(uint256 amount) external onlyOwner {
        reservedTokens += amount;
        emit ReservedTokensAdded(amount);
    }

    // Admin function to update the maximum NFT limit for batch processing
    function updateNFTLimit(uint256 newLimit) external onlyOwner {
        nftLimit = newLimit;
        emit NFTLimitUpdated(newLimit);
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
