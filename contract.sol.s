// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import the ZoKrates generated Verifier contract
import "./Verifier.sol"; // This is the verifier contract generated by ZoKrates

contract ZKProofIPFSData is Verifier {
    // Struct to represent data submission
    struct Data {
        address owner;
        string ipfsHash;
        bool accessGranted;
    }

    // Mapping of users' data to IPFS hash and reward status
    mapping(address => Data) public userData;

    // Event to notify of data submission
    event DataSubmitted(address indexed user, string ipfsHash, uint reward);

    // Event to notify of data revocation
    event DataRevoked(address indexed user);

    // Constructor to initialize contract with a reward pool, etc.
    constructor() payable {
        // The reward pool can be funded with initial amount during contract deployment
    }

    // Function to submit data with zk-SNARK proof
    function submitData(
        string memory ipfsHash,
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[1] memory input
    ) external {
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

        // Emit event
        emit DataSubmitted(msg.sender, ipfsHash, reward);
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
    function withdraw(uint amount) external {
        // Implement access control (e.g., admin only)
        // require(msg.sender == admin);
        payable(msg.sender).transfer(amount);
    }
}
