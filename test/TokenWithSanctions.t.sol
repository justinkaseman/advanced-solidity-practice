// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {TokenWithSanctions} from "../src/TokenWithSanctions.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";

contract TokenWithSanctionsTest is Test {
    TokenWithSanctions public tokenWithSanctions;

    uint256 internal OWNER_PRIVATE_KEY = 0x1;
    address internal OWNER_ADDRESS = vm.addr(OWNER_PRIVATE_KEY);

    uint256 internal STRANGER_1_PRIVATE_KEY = 0x2;
    address internal STRANGER_1_ADDRESS = vm.addr(STRANGER_1_PRIVATE_KEY);
    uint256 internal STRANGER_2_PRIVATE_KEY = 0x3;
    address internal STRANGER_2_ADDRESS = vm.addr(STRANGER_2_PRIVATE_KEY);

    function setUp() public {
        // Deploy contract
        vm.prank(OWNER_ADDRESS, OWNER_ADDRESS);
        tokenWithSanctions = new TokenWithSanctions("SanctionToken", "SAT");
    }

    function test_IsBlocked_Successful() public {
        // Default state is unblocked
        vm.prank(STRANGER_1_ADDRESS, STRANGER_1_ADDRESS);
        assertEq(tokenWithSanctions.isBlocked(STRANGER_1_ADDRESS), false);

        // Block user
        vm.prank(OWNER_ADDRESS, OWNER_ADDRESS);
        tokenWithSanctions.ownerBlock(STRANGER_1_ADDRESS);

        // Expect blocked
        vm.prank(STRANGER_1_ADDRESS, STRANGER_1_ADDRESS);
        assertEq(tokenWithSanctions.isBlocked(STRANGER_1_ADDRESS), true);

        // Unblock user
        vm.prank(OWNER_ADDRESS, OWNER_ADDRESS);
        tokenWithSanctions.ownerUnblock(STRANGER_1_ADDRESS);

        // Expect unblocked
        vm.prank(STRANGER_1_ADDRESS, STRANGER_1_ADDRESS);
        assertEq(tokenWithSanctions.isBlocked(STRANGER_1_ADDRESS), false);
    }

    function test_OwnerBlock_RevertIfNotOwner() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                STRANGER_1_ADDRESS
            )
        );
        // Send as stranger
        vm.prank(STRANGER_1_ADDRESS, STRANGER_1_ADDRESS);
        tokenWithSanctions.ownerBlock(STRANGER_1_ADDRESS);
    }

    function test_OwnerUnblock_RevertIfNotOwner() public {
        // Block user
        vm.prank(OWNER_ADDRESS, OWNER_ADDRESS);
        tokenWithSanctions.ownerBlock(STRANGER_1_ADDRESS);

        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                STRANGER_1_ADDRESS
            )
        );
        // Send as STRANGER
        vm.prank(STRANGER_1_ADDRESS, STRANGER_1_ADDRESS);
        tokenWithSanctions.ownerUnblock(STRANGER_1_ADDRESS);
    }

    function test_Transfer_Successful() public {
        // OWNER gives STRANGER 1 one token
        uint8 decimals = tokenWithSanctions.decimals();
        vm.prank(OWNER_ADDRESS, OWNER_ADDRESS);
        tokenWithSanctions.transfer(STRANGER_1_ADDRESS, 10 ** decimals);

        // STRANGER 1 gives STRANGER 2 one token
        vm.prank(STRANGER_1_ADDRESS, STRANGER_1_ADDRESS);
        tokenWithSanctions.transfer(STRANGER_2_ADDRESS, 10 ** decimals);
    }

    function test_TransferWhenBlocked_reverts() public {
        uint8 decimals = tokenWithSanctions.decimals();

        // OWNER gives STRANGER 1 one token
        vm.prank(OWNER_ADDRESS, OWNER_ADDRESS);
        tokenWithSanctions.transfer(STRANGER_1_ADDRESS, 10 ** decimals);

        // OWNER gives STRANGER 2 one token
        vm.prank(OWNER_ADDRESS, OWNER_ADDRESS);
        tokenWithSanctions.transfer(STRANGER_1_ADDRESS, 10 ** decimals);

        // OWNER blocks STRANGER 1
        vm.prank(OWNER_ADDRESS, OWNER_ADDRESS);
        tokenWithSanctions.ownerBlock(STRANGER_1_ADDRESS);

        // STRANGER 1 cannot give STRANGER 2 one token
        vm.expectRevert(
            abi.encodeWithSelector(
                TokenWithSanctions.AccessBlocked.selector,
                STRANGER_1_ADDRESS
            )
        );
        vm.prank(STRANGER_1_ADDRESS, STRANGER_1_ADDRESS);
        tokenWithSanctions.transfer(STRANGER_2_ADDRESS, 10 ** decimals);

        // STRANGER 2 cannot give STRANGER 1 one token
        vm.expectRevert(
            abi.encodeWithSelector(
                TokenWithSanctions.AccessBlocked.selector,
                STRANGER_1_ADDRESS
            )
        );
        vm.prank(STRANGER_2_ADDRESS, STRANGER_2_ADDRESS);
        tokenWithSanctions.transfer(STRANGER_1_ADDRESS, 10 ** decimals);
    }

    function test_TransferFrom_Successful() public {
        uint8 decimals = tokenWithSanctions.decimals();
        // OWNER gives STRANGER 1 one token
        vm.prank(OWNER_ADDRESS, OWNER_ADDRESS);
        tokenWithSanctions.transfer(STRANGER_1_ADDRESS, 10 ** decimals);

        // STRANGER 1 gives owner approval to transfer one token
        vm.prank(STRANGER_1_ADDRESS, STRANGER_1_ADDRESS);
        tokenWithSanctions.approve(OWNER_ADDRESS, 10 ** decimals);

        // OWNER can transfer from STRANGER 1 to STRANGER 2
        vm.prank(OWNER_ADDRESS, OWNER_ADDRESS);
        tokenWithSanctions.transferFrom(
            STRANGER_1_ADDRESS,
            STRANGER_2_ADDRESS,
            10 ** decimals
        );
    }

    function test_TransferFromWhenBlocked_reverts() public {
        uint8 decimals = tokenWithSanctions.decimals();

        // OWNER gives STRANGER 1 one token
        vm.prank(OWNER_ADDRESS, OWNER_ADDRESS);
        tokenWithSanctions.transfer(STRANGER_1_ADDRESS, 10 ** decimals);

        // OWNER gives STRANGER 2 one token
        vm.prank(OWNER_ADDRESS, OWNER_ADDRESS);
        tokenWithSanctions.transfer(STRANGER_1_ADDRESS, 10 ** decimals);

        // STRANGER 1 gives owner approval to transfer one token
        vm.prank(STRANGER_1_ADDRESS, STRANGER_1_ADDRESS);
        tokenWithSanctions.approve(OWNER_ADDRESS, 10 ** decimals);

        // STRANGER 2 gives owner approval to transfer one token
        vm.prank(STRANGER_2_ADDRESS, STRANGER_2_ADDRESS);
        tokenWithSanctions.approve(OWNER_ADDRESS, 10 ** decimals);

        // OWNER blocks STRANGER 1
        vm.prank(OWNER_ADDRESS, OWNER_ADDRESS);
        tokenWithSanctions.ownerBlock(STRANGER_1_ADDRESS);

        // OWNER cannot transfer from STRANGER 1 to STRANGER 2
        vm.expectRevert(
            abi.encodeWithSelector(
                TokenWithSanctions.AccessBlocked.selector,
                STRANGER_1_ADDRESS
            )
        );
        vm.prank(OWNER_ADDRESS, OWNER_ADDRESS);
        tokenWithSanctions.transferFrom(
            STRANGER_1_ADDRESS,
            STRANGER_2_ADDRESS,
            10 ** decimals
        );

        // OWNER cannot transfer from STRANGER 2 to STRANGER 1
        vm.expectRevert(
            abi.encodeWithSelector(
                TokenWithSanctions.AccessBlocked.selector,
                STRANGER_1_ADDRESS
            )
        );
        vm.prank(OWNER_ADDRESS, OWNER_ADDRESS);
        tokenWithSanctions.transferFrom(
            STRANGER_2_ADDRESS,
            STRANGER_1_ADDRESS,
            10 ** decimals
        );
    }
}
