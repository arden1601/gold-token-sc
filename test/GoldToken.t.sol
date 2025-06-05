// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/GoldToken.sol";
import "../src/GoldPriceOracle.sol";
import "./MockV3Aggregator.sol";

contract GoldTokenTest is Test {
    GoldToken public gld;
    GoldPriceOracle public goldPriceOracle;
    MockV3Aggregator public mockPriceFeed;

    address constant SEPOLIA_GOLD_USD_FEED = 0x214eD9Da11D2fbe465a6fc601a91E62EbEc1a0D6;
    address public owner = makeAddr("owner");
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");

    int256 public GOLD_PRICE = 2300 * 1e8; // $2300 with 8 decimals

    function setUp() public {
        // 1. Deploy Mock Aggregator
        string memory sepoliaRpcUrl = vm.envString("SEPOLIA_RPC_URL");
        require(bytes(sepoliaRpcUrl).length > 0, "SEPOLIA_RPC_URL env var not set");

        // 2. Create a fork of the Sepolia testnet. The 'forkId' is a reference to this fork.
        uint256 forkId = vm.createFork(sepoliaRpcUrl);

        // 3. Select the fork to activate it for the subsequent contract interactions.
        vm.selectFork(forkId);

        // 4. Deploy our GoldPriceOracle contract onto the forked environment.
        // It will be initialized with the real Chainlink feed address.

        // 2. Deploy Oracle (as owner)
        vm.prank(owner);
        goldPriceOracle = new GoldPriceOracle(SEPOLIA_GOLD_USD_FEED);
        GOLD_PRICE = goldPriceOracle.getLatestPrice();

        // 3. Deploy GoldToken (as owner), linking it to the oracle
        vm.prank(owner);
        gld = new GoldToken(address(goldPriceOracle));
    }

    // --- Test Cases ---
    function test_initialTokenProperties() public view {
        assertEq(gld.name(), "Gold Token");
        assertEq(gld.symbol(), "GLD");
        assertEq(gld.decimals(), 18);
        assertEq(gld.owner(), owner);
        assertEq(address(gld.goldPriceOracle()), address(goldPriceOracle));
    }

    function test_getPriceThroughTokenContract() public view {
        int256 price = gld.getLatestGoldPrice();
        assertEq(price, GOLD_PRICE);
    }

    function test_ownerCanMint() public {
        uint256 mintAmount = 100 * 1e18; // 100 GBT

        // Check initial state
        assertEq(gld.balanceOf(user1), 0);
        assertEq(gld.totalSupply(), 0);

        // Owner mints tokens to user1
        vm.prank(owner);
        gld.mint(user1, mintAmount);

        // Check final state
        assertEq(gld.balanceOf(user1), mintAmount);
        assertEq(gld.totalSupply(), mintAmount);
    }

    function test_fail_nonOwnerCannotMint() public {
        uint256 mintAmount = 100 * 1e18;

        // User1 tries to mint tokens, which should fail
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user1));
        gld.mint(user2, mintAmount);
    }

    function test_erc20_transfer() public {
        uint256 initialMint = 100 * 1e18;
        uint256 transferAmount = 30 * 1e18;

        console.log("Initial mint amount:", initialMint);
        // Mint initial tokens to user1
        vm.prank(owner);
        gld.mint(user1, initialMint);

        // User1 transfers tokens to user2
        vm.prank(user1);
        bool success = gld.transfer(user2, transferAmount);
        console.log("user1 balance after transfer:", gld.balanceOf(user1));

        assertTrue(success);
        assertEq(gld.balanceOf(user1), initialMint - transferAmount);
        assertEq(gld.balanceOf(user2), transferAmount);
    }

    function test_ownerCanUpdateOracleAddress() public {
        // Create a new oracle setup with a new price
        int256 newPrice = 9999 * 1e8;
        MockV3Aggregator newMockFeed = new MockV3Aggregator(newPrice);
        vm.prank(owner);
        GoldPriceOracle newOracle = new GoldPriceOracle(address(newMockFeed));

        // Owner updates the oracle address on the token contract
        vm.prank(owner);
        gld.setOracleAddress(address(newOracle));

        // Assert the address was updated
        assertEq(address(gld.goldPriceOracle()), address(newOracle));
        // Assert the token now gets the new price
        assertEq(gld.getLatestGoldPrice(), newPrice);
    }

    function test_fail_nonOwnerCannotUpdateOracleAddress() public {
        // A regular user tries to update the address, which should fail
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user1));
        gld.setOracleAddress(address(0)); // Address doesn't matter, it will fail before checks
    }
}