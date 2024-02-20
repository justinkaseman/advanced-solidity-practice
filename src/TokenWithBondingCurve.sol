// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {ITokenWithBondingCurve} from "./interfaces/ITokenWithBondingCurve.sol";

import {ERC20, IERC20, ERC1363} from "erc1363-payable-token/contracts/token/ERC1363/ERC1363.sol";

/// @title ERC1363 token with a linear bonding curve
/// @author Justin Kaseman
contract TokenWithBondingCurve is
    ERC1363,
    ITokenWithBondingCurve
{
    uint256 private immutable i_slope;

    event Bought(address indexed owner, uint256 amountTokens, uint256 price);
    event Sold(address indexed owner, uint256 amountTokens, uint256 price);

    error NotEnoughNativeProvided(
        uint256 amountProvided,
        uint256 amountRequired
    );
    error NotEnoughTokensOwned(uint256 amountToSell, uint256 amountHeld);
    error TransferFailed();

    /// @dev Constructor to initialize the contract
    /// @param name_ The name of the token
    /// @param symbol_ The symbol of the token
    /// @param slope_ The slope of the linear bonding curve
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 slope_
    ) ERC20(name_, symbol_) {
        i_slope = slope_;
    }

    /// @inheritdoc ITokenWithBondingCurve
    function buy(uint256 _amount) external payable override {
        uint256 price = _calculatePriceForBuy(_amount);
        if (msg.value < price) {
            revert NotEnoughNativeProvided({
                amountProvided: msg.value,
                amountRequired: price
            });
        }
        _mint(msg.sender, _amount);
        (bool success, ) = msg.sender.call{value: msg.value - price}("");
        if (!success) {
            revert TransferFailed();
        }
        emit Bought({owner: msg.sender, amountTokens: _amount, price: price});
    }

    /// @inheritdoc ITokenWithBondingCurve
    function sell(uint256 _amount) external override {
        uint256 balance = balanceOf(msg.sender);
        if (balanceOf(msg.sender) < _amount) {
            revert NotEnoughTokensOwned({
                amountToSell: _amount,
                amountHeld: balance
            });
        }
        uint256 price = _calculatePriceForSell(_amount);
        _burn(msg.sender, _amount);
        (bool success, ) = msg.sender.call{value: price}("");
        if (!success) {
            revert TransferFailed();
        }
        emit Sold({owner: msg.sender, amountTokens: _amount, price: price});
    }

    /// @inheritdoc ITokenWithBondingCurve
    function getCurrentPrice() external view override returns (uint256) {
        return i_slope * totalSupply();
    }

    /// @inheritdoc ITokenWithBondingCurve
    function calculatePriceForBuy(
        uint256 _tokensToBuy
    ) external view returns (uint256) {
        return _calculatePriceForBuy(_tokensToBuy);
    }

    /// @inheritdoc ITokenWithBondingCurve
    function calculatePriceForSell(
        uint256 _tokensToSell
    ) external view override returns (uint256) {
        return _calculatePriceForSell(_tokensToSell);
    }

    /// @dev Calculates the price for buying a certain number of tokens based on a linear bonding curve formula
    /// @param _amount - The number of tokens to buy
    /// @return - The price in wei for the specified amount of tokens
    function _calculatePriceForBuy(
        uint256 _amount
    ) private view returns (uint256) {
        return
            (i_slope *
                (_amount * (_amount + 1) + 2 * totalSupply() * _amount)) / 2;
    }

    /// @dev Calculates the price for selling a certain number of tokens based on a linear bonding curve formula
    /// @param _amount - The number of tokens to sell
    /// @return - The price in wei for the specified number of tokens
    function _calculatePriceForSell(
        uint256 _amount
    ) private view returns (uint256) {
        uint256 totalSupply = totalSupply();
        if (_amount > totalSupply) {
            _amount = totalSupply;
        }
        return
            i_slope *
            ((_amount * (totalSupply + totalSupply - _amount + 1)) / 2);
    }
}
