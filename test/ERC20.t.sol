// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { USDT } from "../contracts/N2D-Sample-Fake-USDT.sol";
import { Test } from "forge-std/Test.sol";

contract ERC20Test is Test {
    USDT public usdt;

    address bob = makeAddr("bob");

    function setUp() public {
        vm.prank(bob);
        usdt = new USDT();
    }

    function test_checkOwner() public view{
        assertEq(address(usdt.owner()), bob);
    }

    function test_shouldRevertWhenNonOwnerCallsMint() public {
        vm.expectRevert();
        usdt.mint(100);
    }

    function test_shouldMintWhenOwnerCallsMint() public {
        vm.prank(bob);
        usdt.mint(100);
        assertEq(usdt.balanceOf(bob), 100);
    }
}