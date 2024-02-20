// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

/// @title Interface for ERC1363 token with a linear bonding curve
interface ITokenWithBondingCurve {
    /// @dev Allows a user to buy tokens using native currency
    /// @param _amount The number of tokens to buy
    function buy(uint256 _amount) external payable;

    /// @dev Allows a user to sell tokens for native currency
    /// @param _amount The number of tokens to sell
    function sell(uint256 _amount) external;

    /// @dev Returns the current price of the token based on the bonding curve formula
    /// @return - The current price of the token in wei
    function getCurrentPrice() external view returns (uint256);

    /// @dev Returns the price for buying a specified number of tokens
    /// @param _tokensToBuy The number of tokens to buy
    /// @return - The price in wei
    function calculatePriceForBuy(
        uint256 _tokensToBuy
    ) external view returns (uint256);

    /// @dev Returns the price for selling a specified number of tokens
    /// @param _tokensToSell The number of tokens to sell
    /// @return - The price in wei
    function calculatePriceForSell(
        uint256 _tokensToSell
    ) external view returns (uint256);
}
