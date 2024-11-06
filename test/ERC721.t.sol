// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;


import { Collection } from "../contracts/N2D-Sample-NFT-Collection.sol";
import { Test, console } from "forge-std/Test.sol";


contract TestCollectionNFT is Test {

    address bob = makeAddr("bob");
    address alice = makeAddr("alice");

    Collection nftCollection;

    function setUp() public {
        nftCollection = new Collection();
    }

    function test__mintingFunction() public {
        vm.prank(bob);
        nftCollection.Mint();
        assertEq(nftCollection.balanceOf(bob), 1);
    }

    function test__walletOfOwnerFunction() public {
        vm.prank(bob);
        nftCollection.Mint();
        uint256[] memory tokenIds = nftCollection.walletOfOwner(bob);
        assertEq(tokenIds.length, 1);
    }
}