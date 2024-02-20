// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {TokenWithBondingCurve} from "../src/TokenWithBondingCurve.sol";

contract TokenWithBondingCurveTest is Test {
    TokenWithBondingCurve public tokenWithBondingCurve;

    uint256 internal STRANGER_PRIVATE_KEY = 0x2;
    address internal STRANGER_ADDRESS = vm.addr(STRANGER_PRIVATE_KEY);

    uint256 STARTING_BALANCE = 10 ether;

    function setUp() public {
        // Deploy contract
        tokenWithBondingCurve = new TokenWithBondingCurve(
            "BondingCurveToken",
            "BCT",
            1 ether // Cost goes up 1 ETH per buy
        );

        // Fund accounts
        vm.deal(STRANGER_ADDRESS, STARTING_BALANCE);
    }

    function test_BuyAndSell_Successful() public {
        // First buy
        vm.prank(STRANGER_ADDRESS, STRANGER_ADDRESS);
        uint256 estimatedCostInWeiFirst = tokenWithBondingCurve
            .calculatePriceForBuy(1);
        uint256 expectedCostInWeiFirst = 1 ether;
        assertEq(estimatedCostInWeiFirst, expectedCostInWeiFirst);

        vm.prank(STRANGER_ADDRESS, STRANGER_ADDRESS);
        tokenWithBondingCurve.buy{value: estimatedCostInWeiFirst}(1);

        assertEq(
            STRANGER_ADDRESS.balance,
            STARTING_BALANCE - estimatedCostInWeiFirst
        );
        assertEq(
            address(tokenWithBondingCurve).balance,
            estimatedCostInWeiFirst
        );
        assertEq(tokenWithBondingCurve.balanceOf(STRANGER_ADDRESS), 1);

        // Second buy
        vm.prank(STRANGER_ADDRESS, STRANGER_ADDRESS);
        uint256 estimatedCostInWeiSecond = tokenWithBondingCurve
            .calculatePriceForBuy(1);
        uint256 expectedCostInWeiSecond = 2 ether;
        assertEq(estimatedCostInWeiSecond, expectedCostInWeiSecond);

        vm.prank(STRANGER_ADDRESS, STRANGER_ADDRESS);
        tokenWithBondingCurve.buy{value: estimatedCostInWeiSecond}(1);

        assertEq(
            STRANGER_ADDRESS.balance,
            STARTING_BALANCE -
                estimatedCostInWeiFirst -
                estimatedCostInWeiSecond
        );
        assertEq(
            address(tokenWithBondingCurve).balance,
            estimatedCostInWeiFirst + estimatedCostInWeiSecond
        );
        assertEq(tokenWithBondingCurve.balanceOf(STRANGER_ADDRESS), 2);

        // First sell
        vm.prank(STRANGER_ADDRESS, STRANGER_ADDRESS);
        uint256 estimatedReturnInWeiFirst = tokenWithBondingCurve
            .calculatePriceForSell(1);
        uint256 expectedReturnInWeiFirst = 2 ether;
        assertEq(estimatedReturnInWeiFirst, expectedReturnInWeiFirst);

        vm.prank(STRANGER_ADDRESS, STRANGER_ADDRESS);
        tokenWithBondingCurve.sell(1);

        assertEq(
            STRANGER_ADDRESS.balance,
            STARTING_BALANCE -
                estimatedCostInWeiFirst -
                estimatedCostInWeiSecond +
                estimatedReturnInWeiFirst
        );
        assertEq(
            address(tokenWithBondingCurve).balance,
            estimatedCostInWeiFirst +
                estimatedCostInWeiSecond -
                estimatedReturnInWeiFirst
        );
        assertEq(tokenWithBondingCurve.balanceOf(STRANGER_ADDRESS), 1);

        // Second sell
        vm.prank(STRANGER_ADDRESS, STRANGER_ADDRESS);
        uint256 estimatedReturnInWeiSecond = tokenWithBondingCurve
            .calculatePriceForSell(1);
        uint256 expectedReturnInWeiSecond = 1 ether;
        assertEq(estimatedReturnInWeiSecond, expectedReturnInWeiSecond);

        vm.prank(STRANGER_ADDRESS, STRANGER_ADDRESS);
        tokenWithBondingCurve.sell(1);

        assertEq(
            STRANGER_ADDRESS.balance,
            STARTING_BALANCE -
                estimatedCostInWeiFirst -
                estimatedCostInWeiSecond +
                estimatedReturnInWeiFirst + estimatedReturnInWeiSecond
        );
        assertEq(
            address(tokenWithBondingCurve).balance,
            estimatedCostInWeiFirst +
                estimatedCostInWeiSecond -
                estimatedReturnInWeiFirst - estimatedReturnInWeiSecond
        );
        assertEq(tokenWithBondingCurve.balanceOf(STRANGER_ADDRESS), 0);
    }
}
