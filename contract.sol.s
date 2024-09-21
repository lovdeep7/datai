// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Verifier.sol";  // Import zk-SNARK verifier contract

contract ZKProofIPFSData is Verifier {
    // Struct to represent data submission
    struct Data {
        address owner;
        string ipfsHash;
        bool accessGranted;
    }

    // Mapping of users' data to IPFS hash and reward status
    mapping(address => Data) public userData;

    // Mapping to track the last submission time of each user
    mapping(address => uint256) public lastSubmission;

    // Mapping to store staked amounts by users
    mapping(address => uint256) public stakes;

    // Cooldown time for bot prevention (e.g., 1 hour = 3600 seconds)
    uint256 public constant SUBMISSION_COOLDOWN = 1 hours;

    // Minimum gas price to prevent bots from spamming (in wei, e.g., 10 gwei)
    uint256 public constant MIN_GAS_PRICE = 10 gwei;

    // Minimum stake required to submit data (in wei)
    uint256 public constant MIN_STAKE = 0.1 ether;

    // Event to notify of data submission
    event DataSubmitted(address indexed user, string ipfsHash, uint reward);

    // Event to notify of data revocation
    event DataRevoked(address indexed user);

    // Event to notify of staking
    event StakeDeposited(address indexed user, uint256 amount);

    // Event to notify of unstaking
    event StakeWithdrawn(address indexed user, uint256 amount);

    // Constructor to initialize contract with a reward pool, etc.
    constructor() payable {
        // Reward pool can be funded with initial amount during contract deployment
        // e.g., reward pool from msg.value
    }

    // Function to deposit stake before submission
    function depositStake() external payable {
        require(msg.value >= MIN_STAKE, "Stake must be at least the minimum required amount");
        stakes[msg.sender] += msg.value;
        emit StakeDeposited(msg.sender, msg.value);
    }

    // Function to submit data with zk-SNARK proof, with stake and bot prevention
    function submitData(
        string memory ipfsHash,
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[1] memory input
    ) external {
        // Ensure the user has enough stake
        require(stakes[msg.sender] >= MIN_STAKE, "Insufficient stake");

        // Check bot prevention mechanisms
        require(block.timestamp >= lastSubmission[msg.sender] + SUBMISSION_COOLDOWN, "Wait for cooldown period");
        require(tx.gasprice >= MIN_GAS_PRICE, "Gas price too low");

        // Verify zk-SNARK proof using the Verifier contract generated by ZoKrates
        require(verifyProof(a, b, c, input), "Invalid ZK proof");

        // Save user's data, associate with IPFS hash
        userData[msg.sender] = Data({
            owner: msg.sender,
            ipfsHash: ipfsHash,
            accessGranted: true
        });

        // Reward the user (this could be a token transfer, etc.)
        uint reward = 1 ether; // Example reward
        payable(msg.sender).transfer(reward);

        // Update last submission time to prevent spamming
        lastSubmission[msg.sender] = block.timestamp;

        // Emit event
        emit DataSubmitted(msg.sender, ipfsHash, reward);
    }

    // Function to withdraw stake
    function withdrawStake(uint256 amount) external {
        require(stakes[msg.sender] >= amount, "Insufficient staked amount");
        require(block.timestamp >= lastSubmission[msg.sender] + SUBMISSION_COOLDOWN, "Cannot withdraw stake immediately after submission");

        // Update the user's stake balance
        stakes[msg.sender] -= amount;

        // Transfer the staked amount back to the user
        payable(msg.sender).transfer(amount);

        // Emit event for stake withdrawal
        emit StakeWithdrawn(msg.sender, amount);
    }

    // Revoke access to data
    function revokeAccess() external {
        // Ensure the user has submitted data
        require(userData[msg.sender].owner == msg.sender, "No data found for this user");

        // Update the access status
        userData[msg.sender].accessGranted = false;

        // Emit event for revocation
        emit DataRevoked(msg.sender);
    }

    // Function to fetch IPFS hash (only if access is granted)
    function getDataHash(address user) external view returns (string memory) {
        require(userData[user].accessGranted, "Access revoked by the user");
        return userData[user].ipfsHash;
    }

    // Fallback function to accept payments (e.g., for reward pool funding)
    receive() external payable {}

    // Optional function to withdraw funds from the contract (admin only)
    function withdrawContractFunds(uint amount) external {
        // Implement access control (e.g., admin only)
        // require(msg.sender == admin);
        payable(msg.sender).transfer(amount);
    }
}
