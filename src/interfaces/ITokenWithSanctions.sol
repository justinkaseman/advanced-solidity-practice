// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

/// @title Interface for ERC1363 with owner sanctions
interface ITokenWithSanctions {
    /// @notice Check if an address is restricted from sending or recieving tokens
    /// @param senderOrReceiver - the address to check the blocked status for
    /// @return - is the senderOrReceiver blocked
    function isBlocked(address senderOrReceiver) external view returns (bool);

    /// @notice Set an address to be restricted from sending or recieving tokens
    /// @notice Only callable by the TokenWithSanctions contract owner
    /// @param senderOrReceiver - the address to block
    function ownerBlock(address senderOrReceiver) external;

    /// @notice Set a previously blocked address to be unrestricted from sending or recieving tokens
    /// @notice Only callable by the TokenWithSanctions contract owner
    /// @param senderOrReceiver - the address to unblock
    function ownerUnblock(address senderOrReceiver) external;
}
