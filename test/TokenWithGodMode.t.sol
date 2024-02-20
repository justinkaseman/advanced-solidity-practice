// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {TokenWithGodMode} from "../src/TokenWithGodMode.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

contract TokenWithGodModeTest is Test {
    TokenWithGodMode public tokenWithGodMode;

    uint256 internal OWNER_PRIVATE_KEY = 0x1;
    address internal OWNER_ADDRESS = vm.addr(OWNER_PRIVATE_KEY);

    uint256 internal GOD_PRIVATE_KEY = 0x2;
    address internal GOD_ADDRESS = vm.addr(GOD_PRIVATE_KEY);

    uint256 internal STRANGER_1_PRIVATE_KEY = 0x3;
    address internal STRANGER_1_ADDRESS = vm.addr(STRANGER_1_PRIVATE_KEY);
    uint256 internal STRANGER_2_PRIVATE_KEY = 0x4;
    address internal STRANGER_2_ADDRESS = vm.addr(STRANGER_2_PRIVATE_KEY);

    function setUp() public {
        // Deploy contract
        vm.prank(OWNER_ADDRESS, OWNER_ADDRESS);
        tokenWithGodMode = new TokenWithGodMode("GodModeToken", "GMT");
    }

    function test_GetGod_Successful() public {
        // Default state of god is 0 address
        vm.prank(STRANGER_1_ADDRESS, STRANGER_1_ADDRESS);
        assertEq(tokenWithGodMode.getGod(), address(0));

        // Owner can set god
        vm.prank(OWNER_ADDRESS, OWNER_ADDRESS);
        tokenWithGodMode.setGod(GOD_ADDRESS);

        // Expect set
        vm.prank(STRANGER_1_ADDRESS, STRANGER_1_ADDRESS);
        assertEq(tokenWithGodMode.getGod(), GOD_ADDRESS);
    }

    function test_SetGod_RevertIfNotOwner() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                STRANGER_1_ADDRESS
            )
        );
        // Send as stranger
        vm.prank(STRANGER_1_ADDRESS, STRANGER_1_ADDRESS);
        tokenWithGodMode.setGod(GOD_ADDRESS);
    }

    function test_TransferFrom_GodPowers() public {
        uint8 decimals = tokenWithGodMode.decimals();
        // OWNER gives STRANGER 1 one token
        vm.prank(OWNER_ADDRESS, OWNER_ADDRESS);
        tokenWithGodMode.transfer(STRANGER_1_ADDRESS, 10 ** decimals);

        // Set god
        vm.prank(OWNER_ADDRESS, OWNER_ADDRESS);
        tokenWithGodMode.setGod(GOD_ADDRESS);

        // GOD can transfer from STRANGER 1 to STRANGER 2 without approval
        vm.prank(GOD_ADDRESS, GOD_ADDRESS);
        tokenWithGodMode.transferFrom(
            STRANGER_1_ADDRESS,
            STRANGER_2_ADDRESS,
            10 ** decimals
        );
    }

    function test_TransferFrom_RevertsAsNonGodWhenNotApproved() public {
        uint8 decimals = tokenWithGodMode.decimals();
        // OWNER gives STRANGER 1 one token
        vm.prank(OWNER_ADDRESS, OWNER_ADDRESS);
        tokenWithGodMode.transfer(STRANGER_1_ADDRESS, 10 ** decimals);

        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientAllowance.selector,
                OWNER_ADDRESS,
                0,
                10 ** decimals
            )
        );

        // OWNER cannot transfer from STRANGER 1 to STRANGER 2 without approval
        vm.prank(OWNER_ADDRESS, OWNER_ADDRESS);
        tokenWithGodMode.transferFrom(
            STRANGER_1_ADDRESS,
            STRANGER_2_ADDRESS,
            10 ** decimals
        );
    }
}
