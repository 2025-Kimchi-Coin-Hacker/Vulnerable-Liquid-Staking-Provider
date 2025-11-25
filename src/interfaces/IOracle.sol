// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IOracle {
    function getRate() external view returns (uint256);
    function setRate(uint256 newRate) external;
}
