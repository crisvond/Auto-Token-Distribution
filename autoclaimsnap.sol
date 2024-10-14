// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/cryptography/MerkleProof.sol";

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract NFTRewardDistributor is Ownable, ReentrancyGuard {
    IERC20 public rewardToken;              // ERC20 Reward Token
    uint256 public rewardPerNFT;            // Reward per NFT
    uint256 public reservedTokens;          // Tokens reserved for rewards
    bytes32 public merkleRoot;              // Merkle root of the ownership snapshot

    bool public paused;                     // Emergency pause flag
    mapping(address => bool) public rewardsClaimed; // Track rewards claimed by users

    event MerkleRootUpdated(bytes32 newMerkleRoot);
    event RewardClaimed(address indexed user, uint256 amount);
    event ReservedTokensAdded(uint256 amount);
    event EmergencyPause(bool status);
    event EmergencyResume(bool status);
    event EmergencyWithdraw(address indexed owner, uint256 amount);

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    constructor(
        address _rewardTokenAddress, 
        uint256 _rewardPerNFT, 
        uint256 _reservedTokens
    ) {
        rewardToken = IERC20(_rewardTokenAddress);
        rewardPerNFT = _rewardPerNFT;
        reservedTokens = _reservedTokens;
        paused = false;
    }

    // Admin function to set the Merkle root based on off-chain snapshot
    function updateMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
        emit MerkleRootUpdated(_merkleRoot);
    }

    // Users can claim their rewards by submitting a Merkle proof
    function claimReward(bytes32[] calldata merkleProof, uint256 amount) external whenNotPaused nonReentrant {
        require(!rewardsClaimed[msg.sender], "Rewards already claimed");
        require(amount > 0, "Invalid reward amount");

        // Verify the Merkle proof
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "Invalid Merkle proof");

        // Transfer reward tokens to the user
        require(reservedTokens >= amount, "Insufficient reserved tokens");
        require(rewardToken.balanceOf(address(this)) >= amount, "Insufficient contract balance");

        reservedTokens -= amount;
        rewardsClaimed[msg.sender] = true;

        rewardToken.transfer(msg.sender, amount);

        emit RewardClaimed(msg.sender, amount);
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
