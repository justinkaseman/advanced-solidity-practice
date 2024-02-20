// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {UntrustedEscrow, Escrow} from "../src/UntrustedEscrow.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    constructor() ERC20("MockERC20", "MERC") {}

    function mint(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }
}

contract UntrustedEscrowTest is Test {
    UntrustedEscrow public untrustedEscrow;
    MockToken public mockToken;

    uint256 internal BUYER_PRIVATE_KEY = 0x2;
    address internal BUYER_ADDRESS = vm.addr(BUYER_PRIVATE_KEY);
    uint256 internal SELLER_PRIVATE_KEY = 0x3;
    address internal SELLER_ADDRESS = vm.addr(SELLER_PRIVATE_KEY);

    function setUp() public {
        untrustedEscrow = new UntrustedEscrow();
        mockToken = new MockToken();
    }

    function test_DepositWithdraw_Successful() public {
        uint256 timelockSeconds = untrustedEscrow.getTimelockSeconds();

        uint256 amount = 10;
        mockToken.mint(BUYER_ADDRESS, amount);

        vm.prank(BUYER_ADDRESS);
        mockToken.approve(address(untrustedEscrow), amount);

        vm.prank(BUYER_ADDRESS);
        Escrow memory escrowData = untrustedEscrow.deposit(
            SELLER_ADDRESS,
            address(mockToken),
            amount
        );

        assertEq(escrowData.escrowId, 1);
        assertEq(escrowData.buyer, BUYER_ADDRESS);
        assertEq(escrowData.erc20TokenAddress, address(mockToken));
        assertEq(escrowData.seller, SELLER_ADDRESS);
        assertEq(
            escrowData.endTimestampSeconds,
            block.timestamp + timelockSeconds
        );
        assertEq(escrowData.amount, amount);

        assertEq(mockToken.balanceOf(BUYER_ADDRESS), 0);
        assertEq(mockToken.balanceOf(address(untrustedEscrow)), amount);

        // Cannot withdraw unless timelock has passed
        vm.expectRevert(
            abi.encodeWithSelector(
                UntrustedEscrow.EscrowTimelockActive.selector
            )
        );
        vm.prank(SELLER_ADDRESS);
        untrustedEscrow.withdraw(
            escrowData.escrowId,
            escrowData.buyer,
            escrowData.erc20TokenAddress,
            escrowData.endTimestampSeconds,
            escrowData.amount
        );

        // Move time past the end of the timelock
        vm.warp(block.timestamp + timelockSeconds);

        // Only seller can withdraw
        vm.expectRevert(
            abi.encodeWithSelector(
                UntrustedEscrow.InvalidEscrow.selector
            )
        );
        untrustedEscrow.withdraw(
            escrowData.escrowId,
            escrowData.buyer,
            escrowData.erc20TokenAddress,
            escrowData.endTimestampSeconds,
            escrowData.amount - 1
        );

        // Cannot withdraw with invalid data
        vm.expectRevert(
            abi.encodeWithSelector(
                UntrustedEscrow.InvalidEscrow.selector
            )
        );
        vm.prank(SELLER_ADDRESS);
        untrustedEscrow.withdraw(
            escrowData.escrowId,
            escrowData.buyer,
            escrowData.erc20TokenAddress,
            escrowData.endTimestampSeconds,
            escrowData.amount - 1
        );

        // Withdraw
        vm.prank(SELLER_ADDRESS);
        untrustedEscrow.withdraw(
            escrowData.escrowId,
            escrowData.buyer,
            escrowData.erc20TokenAddress,
            escrowData.endTimestampSeconds,
            escrowData.amount
        );
        assertEq(mockToken.balanceOf(SELLER_ADDRESS), amount);
        assertEq(mockToken.balanceOf(address(untrustedEscrow)), 0);
    }

    function test_Withdraw_Successful() public {}
}
