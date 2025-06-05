// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/**
 * @title MockV3Aggregator
 * @notice A mock contract for the Chainlink AggregatorV3Interface.
 * It's used for local testing of contracts that consume Chainlink Price Feeds.
 */
contract MockV3Aggregator is AggregatorV3Interface {
    uint8 public constant DECIMALS = 8;
    int256 public latestPrice;

    constructor(int256 _initialPrice) {
        latestPrice = _initialPrice;
    }

    /**
     * @notice Updates the price for testing purposes.
     */
    function updatePrice(int256 _newPrice) external {
        latestPrice = _newPrice;
    }

    // --- AggregatorV3Interface Functions ---

    function decimals() external pure override returns (uint8) {
        return DECIMALS;
    }

    function description() external pure override returns (string memory) {
        return "Mock XAU / USD";
    }

    function version() external pure override returns (uint256) {
        return 1;
    }

    function getRoundData(uint80 /*_roundId*/)
        external
        view
        override
        returns (uint80, int256, uint256, uint256, uint80)
    {
        return (1, latestPrice, block.timestamp, block.timestamp, 1);
    }

    function latestRoundData() external view override returns (uint80, int256, uint256, uint256, uint80) {
        return (1, latestPrice, block.timestamp, block.timestamp, 1);
    }
}