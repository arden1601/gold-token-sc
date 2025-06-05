// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/GoldPriceOracle.sol";
import "./MockV3Aggregator.sol";

contract GoldPriceOracleTest is Test {
    GoldPriceOracle public goldPriceOracle;
    MockV3Aggregator public mockPriceFeed;

    // Define some test users
    address public owner = makeAddr("owner");
    address public user = makeAddr("user");

    // Hardcode a mock price for gold ($2300 with 8 decimals)
    int256 constant STARTING_PRICE = 2300 * 1e8;

    /**
     * @dev Sets up the testing environment before each test case.
     */
    function setUp() public {
        // Deploy the mock Chainlink aggregator
        mockPriceFeed = new MockV3Aggregator(STARTING_PRICE);

        // Deploy the oracle contract, linking it to our mock aggregator
        vm.prank(owner); // Deploy the contract as the 'owner'
        goldPriceOracle = new GoldPriceOracle(address(mockPriceFeed));
    }

    // --- Test Cases ---

    function test_initialDeploymentState() public view {
        assertEq(address(goldPriceOracle.priceFeed()), address(mockPriceFeed));
        assertEq(goldPriceOracle.owner(), owner);
    }

    function test_getLatestPrice() public view {
        int256 currentPrice = goldPriceOracle.getLatestPrice();
        assertEq(currentPrice, STARTING_PRICE);
    }

    function test_ownerCanSetNewPriceFeed() public {
        // Create a new mock feed with a different price
        int256 newPrice = 2500 * 1e8;
        MockV3Aggregator newMockFeed = new MockV3Aggregator(newPrice);

        // The owner updates the price feed address
        vm.prank(owner);
        goldPriceOracle.setPriceFeed(address(newMockFeed));

        // Assert the address was updated
        assertEq(address(goldPriceOracle.priceFeed()), address(newMockFeed));
        // Assert the price now comes from the new feed
        assertEq(goldPriceOracle.getLatestPrice(), newPrice);
    }

    function test_fail_nonOwnerCannotSetPriceFeed() public {
        MockV3Aggregator newMockFeed = new MockV3Aggregator(3000 * 1e8);

        // A regular user tries to update the address, which should fail
        vm.prank(user);
        // We expect the call to revert with an Ownable-specific error message
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        goldPriceOracle.setPriceFeed(address(newMockFeed));
    }

    function test_fail_constructorRevertsOnZeroAddress() public {
        vm.prank(owner);
        // Expect a revert with our custom error message
        vm.expectRevert("GoldPriceOracle: Invalid price feed address");
        new GoldPriceOracle(address(0));
    }
}