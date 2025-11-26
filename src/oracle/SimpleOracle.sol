// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AccessManager} from "../access/AccessManager.sol";

contract SimpleOracle {
    uint256 public price;
    AccessManager public accessManager;

    event PriceUpdated(uint256 newPrice);

    constructor(address _accessManager) {
        accessManager = AccessManager(_accessManager);
        price = 1e18;
    }

    function updatePrice(uint256 newPrice) external {
        price = newPrice;
        emit PriceUpdated(newPrice);
    }

    function getPrice() external view returns (uint256) {
        return price;
    }
}
