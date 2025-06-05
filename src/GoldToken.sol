// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "./GoldPriceOracle.sol"; // Import the new modular oracle contract

/**
 * @title GoldToken
 * @notice An ERC20 token backed by physical gold. Its value is pegged to the
 * real-time price of gold, which is retrieved from the GoldPriceOracle contract.
 * @dev Inherits from OpenZeppelin's ERC20 and Ownable contracts.
 */
contract GoldToken is ERC20, Ownable {
    GoldPriceOracle public goldPriceOracle;

    event OracleAddressUpdated(address indexed newOracleAddress);

    /**
     * @dev Sets the token details and the address of the GoldPriceOracle contract.
     * @param _oracleAddress The deployed address of the GoldPriceOracle contract.
     */
    constructor(address _oracleAddress) ERC20("Gold Token", "GLD") Ownable(msg.sender) {
        require(_oracleAddress != address(0), "GoldToken: Invalid oracle address");
        goldPriceOracle = GoldPriceOracle(_oracleAddress);
    }

    /**
     * @dev Mints new tokens. Can only be called by the owner (the custodian).
     * This function is called by the custodian after verifying a user's physical gold deposit.
     * @param to The address to mint the tokens to.
     * @param amount The amount of tokens to mint (in wei, 18 decimals).
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /**
     * @dev Returns the latest price of gold in USD by querying the oracle contract.
     * @return The latest price with 8 decimals.
     */
    function getLatestGoldPrice() public view returns (int256) {
        return goldPriceOracle.getLatestPrice();
    }

    /**
     * @dev Allows the owner to update the oracle contract address.
     * This adds flexibility, allowing the oracle logic to be upgraded separately.
     * @param _newOracleAddress The new address for the GoldPriceOracle contract.
     */
    function setOracleAddress(address _newOracleAddress) external onlyOwner {
        require(_newOracleAddress != address(0), "GoldToken: Invalid new oracle address");
        goldPriceOracle = GoldPriceOracle(_newOracleAddress);
        emit OracleAddressUpdated(_newOracleAddress);
    }
}