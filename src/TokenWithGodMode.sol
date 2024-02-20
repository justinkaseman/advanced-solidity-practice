// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {ITokenWithGodMode} from "./interfaces/ITokenWithGodMode.sol";

import {ERC20, IERC20, ERC1363} from "erc1363-payable-token/contracts/token/ERC1363/ERC1363.sol";
import {Ownable, Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";

/// @title ERC1363 with god account
/// @author Justin Kaseman
contract TokenWithGodMode is ERC1363, Ownable2Step, ITokenWithGodMode {
    address private s_god;

    event GodSet(address indexed newGod);

    /// @dev Constructor to initialize the contract
    /// @param name_ The name of the token
    /// @param symbol_ The symbol of the token
    constructor(
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) Ownable(msg.sender) {
        _mint(msg.sender, 100 * 10 ** uint256(decimals()));
    }

    /// @inheritdoc ITokenWithGodMode
    function getGod() external view returns (address) {
        return s_god;
    }

    /// @inheritdoc ITokenWithGodMode
    function setGod(address god_) external onlyOwner {
        s_god = god_;
        emit GodSet(god_);
    }

    /// @dev See {IERC20-allowance}.
    /// @dev Overriden to allow God address can transfer tokens between addresses freely
    function allowance(
        address owner,
        address spender
    ) public view virtual override(ERC20, IERC20) returns (uint256) {
        if (msg.sender == s_god) {
            return type(uint256).max;
        }
        return super.allowance(owner, spender);
    }
}
