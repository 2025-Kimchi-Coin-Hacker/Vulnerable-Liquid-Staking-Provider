// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ILSToken {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function totalSupply() external view returns (uint256);
}

import {ValidatorRegistry} from "./ValidatorRegistry.sol";

contract StakingManager {
    ILSToken public lsToken;
    ValidatorRegistry public validatorRegistry;

    event Staked(address indexed user, uint256 ethAmount, uint256 tokenAmount);
    event Unstaked(address indexed user, uint256 ethAmount, uint256 tokenAmount);
    event RewardsDistributed(uint256 amount);

    constructor(address _lsToken, address _validatorRegistry) {
        lsToken = ILSToken(_lsToken);
        validatorRegistry = ValidatorRegistry(_validatorRegistry);
    }

    function getSharesByEth(uint256 ethAmount) public view returns (uint256) {
        uint256 totalAssets = address(this).balance;
        uint256 totalSupply = lsToken.totalSupply();

        if (totalSupply == 0 || totalAssets == 0) {
            return ethAmount;
        }
        return (ethAmount * totalSupply) / totalAssets;
    }

    function getEthByShares(uint256 sharesAmount) public view returns (uint256) {
        uint256 totalAssets = address(this).balance;
        uint256 totalSupply = lsToken.totalSupply();

        if (totalSupply == 0) return 0;
        return (sharesAmount * totalAssets) / totalSupply;
    }

    function stake() external payable {
        require(msg.value > 0, "Cannot stake 0");

        uint256 totalAssets = address(this).balance - msg.value;
        uint256 totalSupply = lsToken.totalSupply();
        uint256 sharesToMint;

        if (totalSupply == 0 || totalAssets == 0) {
            sharesToMint = msg.value;
        } else {
            sharesToMint = (msg.value * totalSupply) / totalAssets;
        }

        lsToken.mint(msg.sender, sharesToMint);

        validatorRegistry.distributeStakeToValidators(msg.value);

        emit Staked(msg.sender, msg.value, sharesToMint);
    }

    function unstake(uint256 shares) external {
        require(shares > 0, "Cannot unstake 0");

        uint256 totalAssets = address(this).balance;
        uint256 totalSupply = lsToken.totalSupply();

        uint256 ethAmount = (shares * totalAssets) / totalSupply;

        lsToken.burn(msg.sender, shares);

        (bool success,) = msg.sender.call{value: ethAmount}("");
        require(success, "Transfer failed");

        emit Unstaked(msg.sender, ethAmount, shares);
    }

    receive() external payable {
        emit RewardsDistributed(msg.value);
    }
}

