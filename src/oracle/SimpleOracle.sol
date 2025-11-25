// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IOracle} from "../interfaces/IOracle.sol";

/// @notice Open oracle where anyone can set the rate, allowing manipulation/sandwich.
contract SimpleOracle is IOracle {
    uint256 private rate;

    event RateUpdated(uint256 newRate);

    constructor() {
        rate = 1e18; // 1:1 by default
    }

    function getRate() external view override returns (uint256) {
        return rate;
    }

    function setRate(uint256 newRate) external override {
        rate = newRate;
        emit RateUpdated(newRate);
    }
}
