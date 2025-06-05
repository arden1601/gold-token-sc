// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

/**
 * @title GoldPriceOracle
 * @notice This contract is responsible for fetching the latest price of Gold (XAU)
 * in USD from a Chainlink Price Feed. It is designed to be a modular component
 * that other contracts can query.
 */
contract GoldPriceOracle is Ownable {
    AggregatorV3Interface public priceFeed;

    event PriceFeedUpdated(address indexed newFeedAddress);

    /**
     * @dev Sets the initial Chainlink price feed address during deployment.
     * @param _priceFeedAddress The address for the Chainlink XAU / USD price feed.
     */
    constructor(address _priceFeedAddress) Ownable(msg.sender) {
        require(_priceFeedAddress != address(0), "GoldPriceOracle: Invalid price feed address");
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    /**
     * @dev Returns the latest price of gold from the Chainlink feed.
     * The price is returned with 8 decimals, as per the Chainlink XAU/USD feed standard.
     * @return The latest price.
     */
    function getLatestPrice() public view returns (int256) {
        (
            /*uint80 roundID*/,
            int256 price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return price;
    }

    /**
     * @dev Allows the owner to update the price feed address.
     * This is useful if Chainlink updates its feeds or for migrating networks.
     * @param _newPriceFeedAddress The new address for the Chainlink price feed.
     */
    function setPriceFeed(address _newPriceFeedAddress) external onlyOwner {
        require(_newPriceFeedAddress != address(0), "GoldPriceOracle: Invalid new price feed address");
        priceFeed = AggregatorV3Interface(_newPriceFeedAddress);
        emit PriceFeedUpdated(_newPriceFeedAddress);
    }
}