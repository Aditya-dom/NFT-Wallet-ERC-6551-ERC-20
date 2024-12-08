// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {MultiSigWallet} from "contracts/Multi-Signature/MultiSignature.sol";

contract MultiSigWalletTest is Test {
    MultiSigWallet wallet;
    address[] owners;
    uint256 threshold;

    function setUp() public {
        // Define test owners and threshold
        owners = [address(1), address(2), address(3)];
        threshold = 2;

        // Deploy the MultiSigWallet contract
        wallet = new MultiSigWallet(owners, threshold);

        // Fund the wallet with some Ether
        vm.deal(address(wallet), 10 ether);
    }

    function testInitialization() public {
        // Check initial owners
        for (uint256 i = 0; i < owners.length; i++) {
            assertTrue(wallet.isOwner(owners[i]));
        }

        // Check initial threshold
        assertEq(wallet.threshold(), threshold);
    }

    function testSubmitTransaction() public {
        address payable to = payable(address(4));
        uint256 value = 1 ether;
        bytes memory data = "";

        vm.prank(address(1)); // Simulate transaction from owner[1]
        uint256 txId = wallet.submitTransaction(to, value, data);

        (address toAddr, uint256 val, , bool executed, uint256 confirmations) = wallet.transactions(txId);

        assertEq(toAddr, to);
        assertEq(val, value);
        assertFalse(executed);
        assertEq(confirmations, 0);
    }

    function testConfirmTransaction() public {
        address payable to = payable(address(4));
        uint256 value = 1 ether;
        bytes memory data = "";

        vm.prank(address(1));
        uint256 txId = wallet.submitTransaction(to, value, data);

        vm.prank(address(2));
        wallet.confirmTransaction(txId);

        (, , , , uint256 confirmations) = wallet.transactions(txId);
        assertEq(confirmations, 1);

        vm.prank(address(3));
        wallet.confirmTransaction(txId);

        (, , , , confirmations) = wallet.transactions(txId);
        assertEq(confirmations, 2);
    }

    function testExecuteTransaction() public {
    // Create a new transaction
    address payable to = payable(address(4));
    uint256 value = 1 ether;
    bytes memory data = "";

    // Submit the transaction as owner[1]
    vm.prank(address(1));
    uint256 txId = wallet.submitTransaction(to, value, data);

    // Confirm the transaction by owner[2] and owner[3]
    vm.prank(address(2));
    wallet.confirmTransaction(txId);

    vm.prank(address(3));
    wallet.confirmTransaction(txId);

    // Verify that the transaction is marked as executed
    (, , , bool executed,) = wallet.transactions(txId);
    assertTrue(executed);
}



    function testAddOwner() public {
        address newOwner = address(5);

        vm.prank(address(1)); // Only an owner can call this
        wallet.addOwner(newOwner);

        assertTrue(wallet.isOwner(newOwner));
    }

    function testRemoveOwner() public {
        address ownerToRemove = address(3);

        vm.prank(address(1)); // Only an owner can call this
        wallet.removeOwner(ownerToRemove);

        assertFalse(wallet.isOwner(ownerToRemove));
    }

    function testChangeThreshold() public {
        uint256 newThreshold = 3;

        vm.prank(address(1)); // Only an owner can call this
        wallet.changeThreshold(newThreshold);

        assertEq(wallet.threshold(), newThreshold);
    }

    function testFailSubmitTransactionByNonOwner() public {
        address nonOwner = address(6);
        
        vm.prank(nonOwner); // Simulate a non-owner calling the method
       
       // This should fail because only an owner can submit a transaction
       wallet.submitTransaction(payable(address(4)), 1 ether, "");
    }
}