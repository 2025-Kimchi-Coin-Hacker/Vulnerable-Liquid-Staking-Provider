// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract RewardDistributor {
    mapping(address => uint256) public rewards;
    uint256 public totalRewards;

    event RewardsDistributed(uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);

    function distributeRewards() external payable {
        require(msg.value > 0, "No rewards");
        totalRewards += msg.value;
        emit RewardsDistributed(msg.value);
    }

    function accrueReward(address user, uint256 amount) external {
        rewards[user] += amount;
    }

    function claimRewards() external {
        uint256 amount = rewards[msg.sender];
        require(amount > 0, "No rewards to claim");

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        rewards[msg.sender] = 0;

        emit RewardsClaimed(msg.sender, amount);
    }

    function pendingRewards(address user) external view returns (uint256) {
        return rewards[user];
    }
}

