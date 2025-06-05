// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/GoldPriceOracle.sol";
import "../src/GoldToken.sol";

/**
 * @notice Deploys the modular GoldPriceOracle and GoldToken contracts.
 */
contract DeployContracts is Script {
    function run() external returns (GoldToken, GoldPriceOracle) {
        // --- Configuration ---
        // This is the real, verified Chainlink XAU/USD Price Feed address on Sepolia.
        address priceFeedAddress = 0x214eD9Da11D2fbe465a6fc601a91E62EbEc1a0D6;

        // Load the deployer's private key from the .env file.
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        console.log("Deploying contracts with private key:", deployerPrivateKey);

        // --- Deployment ---
        // Begin broadcasting transactions signed with the deployer's key.
        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy the GoldPriceOracle contract first.
        GoldPriceOracle goldPriceOracle = new GoldPriceOracle(priceFeedAddress);
        console.log("GoldPriceOracle deployed to:", address(goldPriceOracle));

        // 2. Deploy the GoldToken, passing the new oracle's address to its constructor.
        GoldToken goldBackedToken = new GoldToken(address(goldPriceOracle));
        console.log("GoldToken deployed to:", address(goldBackedToken));

        // Stop broadcasting transactions.
        vm.stopBroadcast();

        return (goldBackedToken, goldPriceOracle);
    }
}