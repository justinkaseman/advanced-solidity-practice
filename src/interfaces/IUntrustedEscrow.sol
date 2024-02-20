// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

/// @title Interface for escrow contract for ERC20 tokens
interface IUntrustedEscrow {
    /// @notice Get the timelock time
    /// @return - The amount of seconds that need to pass before the seller can withdraw the escrowed funds
    function getTimelockSeconds() external pure returns (uint256);

    /// @notice A buyer can lock tokens that can only be withdrawn after a timelock has passed
    /// @param seller - The address that will be able to withdraw the tokens
    /// @param erc20TokenAddress - The address of an ERC20 compatible token to store in escrow
    /// @return escrowData - see Escrow struct at the bottom of this file
    function deposit(
        address seller,
        address erc20TokenAddress,
        uint256 amount
    ) external returns (Escrow memory escrowData);

    /// @notice A seller can withdraw the locked tokens after the timelock has passed
    /// @param escrowId - A unique identifier of the escrow agreement
    /// @param buyer - The address of the depositor
    /// @param erc20TokenAddress - The address of an ERC20 compatible token to store in escrow
    /// @param endTimestampSeconds - The block timestamp in seconds that the tokens can be withdrawn at
    /// @param amount - The amount of tokens that are in escrow
    function withdraw(
        uint256 escrowId,
        address buyer,
        address erc20TokenAddress,
        uint48 endTimestampSeconds,
        uint256 amount
    ) external;

    /// @notice Deposit tokens
    /// @param escrowId - A unique identifier of the escrow agreement
    /// @param buyer - The address of the depositor
    /// @param erc20TokenAddress - The address of an ERC20 compatible token to store in escrow
    /// @param endTimestampSeconds - The block timestamp in seconds that the tokens can be withdrawn at
    /// @param amount - The amount of tokens that are in escrow
    /// @return - If the given data is a valid escrow agreement
    function isValidEscrow(
        uint256 escrowId,
        address buyer,
        address erc20TokenAddress,
        uint48 endTimestampSeconds,
        uint256 amount
    ) external view returns (bool);
}

struct Escrow {
    uint256 escrowId; // A unique identifier of the escrow agreement
    address buyer; // The address of the depositor
    address erc20TokenAddress; // The address of an ERC20 compatible token to store in escrow
    address seller; // The address of the withdrawer
    uint48 endTimestampSeconds; // The block timestamp in seconds that the tokens can be withdrawn at
    uint256 amount; // The amount of tokens that are in escrow
}
