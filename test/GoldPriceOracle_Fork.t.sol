// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/GoldPriceOracle.sol";

/**
 * @title GoldPriceOracleForkTest
 * @notice This test suite performs integration testing on the GoldPriceOracle contract
 * by forking the Sepolia testnet and interacting with the live Chainlink price feed.
 */
contract GoldPriceOracleForkTest is Test {
    // The real, live address of the XAU/USD price feed on the Sepolia testnet.
    address constant SEPOLIA_XAU_USD_FEED = 0x214eD9Da11D2fbe465a6fc601a91E62EbEc1a0D6;

    // The address where we will deploy our oracle contract.
    GoldPriceOracle public goldPriceOracle;

    /**
     * @dev Sets up the testing environment. This function runs before each test.
     * It reads the Sepolia RPC URL from the .env file and creates a fork.
     */
    function setUp() public {
        // 1. Get the RPC URL from your .env file
        string memory sepoliaRpcUrl = vm.envString("SEPOLIA_RPC_URL");
        require(bytes(sepoliaRpcUrl).length > 0, "SEPOLIA_RPC_URL env var not set");

        // 2. Create a fork of the Sepolia testnet. The 'forkId' is a reference to this fork.
        uint256 forkId = vm.createFork(sepoliaRpcUrl);

        // 3. Select the fork to activate it for the subsequent contract interactions.
        vm.selectFork(forkId);

        // 4. Deploy our GoldPriceOracle contract onto the forked environment.
        // It will be initialized with the real Chainlink feed address.
        goldPriceOracle = new GoldPriceOracle(SEPOLIA_XAU_USD_FEED);
    }

    /**
     * @notice Tests if the contract can successfully call the live Chainlink feed
     * on the forked Sepolia network and retrieve a valid price.
     */
    function test_fork_getLatestPriceFromRealOracle() public {
        // Call the function to get the latest price from the live oracle
        int256 latestPrice = goldPriceOracle.getLatestPrice();

        // We can't assert an exact price because it's live data.
        // Instead, we perform sanity checks to ensure the data is reasonable.

        // Log the retrieved price to the console for manual verification.
        // The price has 8 decimals, so a value of 230000000000 means $2300.00.
        console.log("Retrieved Live Gold Price (8 decimals):", latestPrice);

        // 1. Check that the price is not zero.
        assertTrue(latestPrice != 0, "Price should not be zero");

        // 2. Check that the price is within a reasonable range (e.g., $1,000 to $10,000).
        // These bounds are arbitrary and just for sanity checking.
        int256 lowerBound = 1000 * 1e8; // $1,000
        int256 upperBound = 10000 * 1e8; // $10,000

        assertTrue(latestPrice > lowerBound, "Price is below the expected lower bound.");
        assertTrue(latestPrice < upperBound, "Price is above the expected upper bound.");
    }
}