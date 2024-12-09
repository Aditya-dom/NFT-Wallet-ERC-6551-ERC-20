// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {MultiSigWallet} from "contracts/Multi-Signature/MultiSignature.sol";

contract MultiSigWalletTest is Test {
    MultiSigWallet wallet;
    address owner1 = address(0x1);
    address owner2 = address(0x2);
    address owner3 = address(0x3);
    address nonOwner = address(0x4);

    function setUp() public {
        // Deploy MultiSigWallet with 3 owners and a threshold of 2
        address[] memory owners = new address[](3);
        owners[0] = owner1;
        owners[1] = owner2;
        owners[2] = owner3;

        vm.prank(owner1); // Simulate deployment by owner1
        wallet = new MultiSigWallet(owners, 2);
    }

    function testConstructor() public {
        // Ensure owners are set correctly
        assertEq(wallet.isOwner(owner1), true);
        assertEq(wallet.isOwner(owner2), true);
        assertEq(wallet.isOwner(owner3), true);
        assertEq(wallet.isOwner(nonOwner), false);

        // Ensure threshold is set correctly
        assertEq(wallet.threshold(), 2);
    }

    function testSubmitTransaction() public {
        vm.prank(owner1); // Simulate transaction submission by owner1
        uint256 txId = wallet.submitTransaction(payable(address(0x5)), 1 ether, "");

        // Check transaction details
        (address to, uint256 value, bytes memory data, bool executed, uint256 confirmations) = wallet.transactions(txId);
        assertEq(to, address(0x5));
        assertEq(value, 1 ether);
        assertEq(data.length, 0); // Empty data
        assertEq(executed, false);
        assertEq(confirmations, 0);
    }

    // function testConfirmTransaction() public {
    //     vm.prank(owner1); // Simulate transaction submission by owner1
    //     uint256 txId = wallet.submitTransaction(payable(address(0x5)), 1 ether, "");

    //     vm.prank(owner2); // Simulate confirmation by owner2
    //     wallet.confirmTransaction(txId);

    //     (, , , , uint256 confirmations) = wallet.transactions(txId);
    //     assertEq(confirmations, 1);

    //     vm.prank(owner3); // Simulate confirmation by owner3
    //     wallet.confirmTransaction(txId);

    //     (, , , , confirmations) = wallet.transactions(txId);
    //     assertEq(confirmations, 2);
    // }

    // function testExecuteTransaction() public {
    //     vm.deal(address(wallet), 10 ether); // Fund the contract with Ether

    //     vm.prank(owner1); // Simulate transaction submission by owner1
    //     uint256 txId = wallet.submitTransaction(payable(address(0x5)), 1 ether, "");

    //     vm.prank(owner2); // Confirm transaction by owner2
    //     wallet.confirmTransaction(txId);

    //     vm.prank(owner3); // Confirm transaction by owner3 (meets threshold)
    //     wallet.confirmTransaction(txId);

    //     vm.prank(owner1); // Execute transaction by owner1
    //     wallet.executeTransaction(txId);

    //     (, , , bool executed, ) = wallet.transactions(txId);
    //     assertEq(executed, true);

    //     // Check balance of recipient
    //     assertEq(address(0x5).balance, 1 ether);
    // }

    function testAddOwner() public {
        vm.prank(owner1); // Only an existing owner can add a new owner
        wallet.addOwner(nonOwner);

        assertEq(wallet.isOwner(nonOwner), true);
    }

    function testRemoveOwner() public {
        vm.prank(owner1); // Only an existing owner can remove an owner
        wallet.removeOwner(owner3);

        assertEq(wallet.isOwner(owner3), false);

        // Ensure threshold is adjusted if necessary
        assertEq(wallet.threshold(), 2); // Threshold remains valid as there are still two owners left
    }

    function testChangeThreshold() public {
        vm.prank(owner1); // Only an existing owner can change the threshold
        wallet.changeThreshold(3);

        assertEq(wallet.threshold(), 3);
    }

    function testRevertInvalidThreshold() public {
        vm.expectRevert(MultiSigWallet.InvalidThreshold.selector); // Expect revert for invalid threshold

        vm.prank(owner1);
        wallet.changeThreshold(4); // Invalid as there are only three owners
    }

//     function testRevertNotAnOwner() public {
//         vm.expectRevert("Ownable: caller is not the owner"); // Expect OpenZeppelin's Ownable error

//         vm.prank(nonOwner);
//         wallet.addOwner(address(0x6)); // Non-owner trying to add a new owner
//     }
}