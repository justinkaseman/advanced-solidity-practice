// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {ITokenWithSanctions} from "./interfaces/ITokenWithSanctions.sol";

import {ERC20, IERC20, ERC1363} from "erc1363-payable-token/contracts/token/ERC1363/ERC1363.sol";
import {Ownable, Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";

/// @title ERC1363 with owner sanctions
/// @author Justin Kaseman
contract TokenWithSanctions is ERC1363, Ownable2Step, ITokenWithSanctions {
    mapping(address => bool) s_isBlockedList;

    event Blocked(address indexed senderOrReceiver);
    event Unblocked(address indexed senderOrReceiver);

    error IsBlockedAlreadySet(bool isBlocked);
    error AccessBlocked(address senderOrReceiver);

    /// @dev Constructor to initialize the contract
    /// @param name_ The name of the token
    /// @param symbol_ The symbol of the token
    constructor(
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) Ownable(msg.sender) {
        _mint(msg.sender, 100 * 10 ** uint256(decimals()));
    }

    /// @inheritdoc ITokenWithSanctions
    function isBlocked(
        address senderOrReceiver
    ) external view override returns (bool) {
        return s_isBlockedList[senderOrReceiver];
    }

    /// @inheritdoc ITokenWithSanctions
    function ownerBlock(address senderOrReceiver) external override onlyOwner {
        if (s_isBlockedList[senderOrReceiver]) {
            revert IsBlockedAlreadySet({isBlocked: true});
        }
        s_isBlockedList[senderOrReceiver] = true;
        emit Blocked(senderOrReceiver);
    }

    /// @inheritdoc ITokenWithSanctions
    function ownerUnblock(
        address senderOrReceiver
    ) external override onlyOwner {
        if (s_isBlockedList[senderOrReceiver] == false) {
            revert IsBlockedAlreadySet({isBlocked: false});
        }
        s_isBlockedList[senderOrReceiver] = false;
        emit Unblocked(senderOrReceiver);
    }

    /// @notice Checks if a sender or recipient is blocked before proceeding
    /// @inheritdoc IERC20
    function transfer(
        address to,
        uint256 value
    ) public virtual override(ERC20, IERC20) returns (bool) {
        address sender = _msgSender();
        _onlyNotBlocked(sender, to);
        return super.transfer(to, value);
    }

    /// @notice Checks if a sender or recipient is blocked before proceeding
    /// @inheritdoc IERC20
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public virtual override(ERC20, IERC20) returns (bool) {
        _onlyNotBlocked(from, to);
        return super.transferFrom(from, to, value);
    }

    /// @dev Only allow isBlockedList[address] of false
    function _onlyNotBlocked(address sender, address recipient) private view {
        if (s_isBlockedList[sender]) {
            revert AccessBlocked({senderOrReceiver: sender});
        }
        if (s_isBlockedList[recipient]) {
            revert AccessBlocked({senderOrReceiver: recipient});
        }
    }
}
