// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IOracle {
    function updatePrice(uint256 newPrice) external; // Vulnerable to Sandwich
    function getPrice() external view returns (uint256);
}
