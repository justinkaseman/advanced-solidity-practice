// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {IUntrustedEscrow, Escrow} from "./interfaces/IUntrustedEscrow.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

/// @title Escrow contract for ERC20 tokens
/// @author Justin Kaseman
contract UntrustedEscrow is IUntrustedEscrow {
    using SafeERC20 for IERC20;

    uint256 internal constant TIMELOCK_SECONDS = 3 days;

    uint256 internal s_totalEscrowCount;

    mapping(uint256 escrowId => bytes32 escrowHash) internal s_escrows;

    event Deposited(
        uint256 indexed escrowId,
        address buyer,
        address erc20TokenAddress,
        address seller,
        uint48 endTimestampSeconds,
        uint256 amount
    );
    event Withdrawn(uint256 indexed escrowId);

    error NoZeroAmount(bool isZeroAfterFees);
    error InvalidEscrow();
    error EscrowTimelockActive();

    constructor() {}

    function getTimelockSeconds() public pure returns (uint256) {
        return TIMELOCK_SECONDS;
    }

    function deposit(
        address seller,
        address erc20TokenAddress,
        uint256 amount
    ) external returns (Escrow memory escrowData) {
        if (amount == 0) {
            revert NoZeroAmount({isZeroAfterFees: false});
        }

        uint256 balanceBefore = IERC20(erc20TokenAddress).balanceOf(
            address(this)
        );
        IERC20(erc20TokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
        uint256 balanceAfter = IERC20(erc20TokenAddress).balanceOf(
            address(this)
        );

        uint256 amountAfterFees = balanceAfter - balanceBefore;
        if (amountAfterFees == 0) {
            revert NoZeroAmount({isZeroAfterFees: true});
        }

        uint256 escrowId = ++s_totalEscrowCount;

        uint48 endTimestampSeconds = SafeCast.toUint48(
            block.timestamp + TIMELOCK_SECONDS
        );

        escrowData = Escrow({
            escrowId: escrowId,
            buyer: msg.sender,
            erc20TokenAddress: erc20TokenAddress,
            seller: seller,
            endTimestampSeconds: endTimestampSeconds,
            amount: amountAfterFees
        });

        bytes32 escrowHash = keccak256(abi.encode(escrowData));
        s_escrows[escrowId] = escrowHash;

        emit Deposited({
            escrowId: escrowId,
            buyer: msg.sender,
            erc20TokenAddress: erc20TokenAddress,
            amount: amountAfterFees,
            seller: seller,
            endTimestampSeconds: endTimestampSeconds
        });

        return escrowData;
    }

    function withdraw(
        uint256 escrowId,
        address buyer,
        address erc20TokenAddress,
        uint48 endTimestampSeconds,
        uint256 amount
    ) external {
        if (
            !_isValidEscrow(
                escrowId,
                buyer,
                erc20TokenAddress,
                msg.sender,
                endTimestampSeconds,
                amount
            )
        ) {
            revert InvalidEscrow();
        }

        if (block.timestamp < endTimestampSeconds) {
            revert EscrowTimelockActive();
        }

        delete s_escrows[escrowId];

        IERC20(erc20TokenAddress).safeTransfer(msg.sender, amount);

        emit Withdrawn(escrowId);
    }

    function isValidEscrow(
        uint256 escrowId,
        address buyer,
        address erc20TokenAddress,
        uint48 endTimestampSeconds,
        uint256 amount
    ) external view returns (bool) {
        return
            _isValidEscrow(
                escrowId,
                buyer,
                erc20TokenAddress,
                msg.sender,
                endTimestampSeconds,
                amount
            );
    }

    function _isValidEscrow(
        uint256 escrowId,
        address buyer,
        address erc20TokenAddress,
        address seller,
        uint48 endTimestampSeconds,
        uint256 amount
    ) internal view returns (bool) {
        bytes32 escrowHash = keccak256(
            abi.encode(
                Escrow({
                    escrowId: escrowId,
                    buyer: buyer,
                    erc20TokenAddress: erc20TokenAddress,
                    seller: seller,
                    endTimestampSeconds: endTimestampSeconds,
                    amount: amount
                })
            )
        );
        return s_escrows[escrowId] == escrowHash;
    }
}
