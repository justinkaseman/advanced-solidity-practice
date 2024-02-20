// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

/// @title Interface for ERC1363 with god account
interface ITokenWithGodMode {
    /// @notice Retrieve the currently set god account, that can move tokens freely between all addresses
    /// @return - god address
    function getGod() external view returns (address);
   
    /// @notice Set the god account, that can move tokens freely between all addresses
    /// @param god_ - the address to set as the god account
    function setGod(address god_) external;
}


