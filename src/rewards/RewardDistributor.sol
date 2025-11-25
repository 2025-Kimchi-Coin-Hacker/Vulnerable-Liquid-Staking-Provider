// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IRewardDistributor} from "../interfaces/IRewardDistributor.sol";

/// @notice Naive reward escrow vulnerable to reentrancy and underfunding.
contract RewardDistributor is IRewardDistributor {
    address public manager;
    mapping(address => uint256) public rewards;

    event RewardAccrued(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);

    modifier onlyManager() {
        require(msg.sender == manager, "not manager");
        _;
    }

    constructor(address _manager) {
        manager = _manager;
    }

    function accrue(address user, uint256 amount) external override onlyManager {
        rewards[user] += amount;
        emit RewardAccrued(user, amount);
    }

    /// @dev Vulnerable: external call before zeroing allows reentrancy and double-claim.
    function claim() external override {
        uint256 amount = rewards[msg.sender];
        require(amount > 0, "no rewards");
        (bool ok,) = payable(msg.sender).call{value: amount}("");
        require(ok, "send failed");
        rewards[msg.sender] = 0;
        emit RewardClaimed(msg.sender, amount);
    }

    function pending(address user) external view override returns (uint256) {
        return rewards[user];
    }

    receive() external payable {}
}
