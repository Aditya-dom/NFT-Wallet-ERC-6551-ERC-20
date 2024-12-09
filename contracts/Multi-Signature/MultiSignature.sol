// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import {QMath} from "contracts/Common/QMath.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

/**
 * @author Meet Jain - @meetjn
 * @title MultiSignature - A multi-signature wallet with support for confirmations using signed messages.
 * @dev A simplified multi-signature wallet contract that allows multiple owners to approve transactions.
 */

contract MultiSigWallet is Ownable {
    using QMath for uint256;

    // Custom errors
    error NotAnOwner();
    error TransactionDoesNotExist();
    error TransactionAlreadyExecuted();
    error TransactionAlreadyConfirmed();
    error InvalidOwnerAddress();
    error OwnerNotUnique();
    error InvalidThreshold();
    error NotEnoughConfirmations();
    error TransactionFailed();

    // Events
    event Deposit(address indexed sender, uint256 amount);
    event TransactionSubmitted(uint256 indexed transactionId);
    event TransactionConfirmed(address indexed owner, uint256 indexed transactionId);
    event TransactionExecuted(uint256 indexed transactionId);
    event OwnerAdded(address indexed newOwner);
    event OwnerRemoved(address indexed removedOwner);
    event ThresholdChanged(uint256 newThreshold);

    // State variables
    address[] public owners; // List of wallet owners
    mapping(address => bool) public isOwner; // Mapping to check if an address is an owner
    uint256 public threshold; // Minimum number of approvals required for a transaction

    struct Transaction {
        address payable to; // Destination address
        uint256 value; // Amount of Ether to send
        bytes data; // Data payload (e.g., function call)
        bool executed; // Whether the transaction has been executed
        uint256 confirmations; // Number of confirmations received
    }

    Transaction[] public transactions; // Array of all submitted transactions
    mapping(uint256 => mapping(address => bool)) public confirmations; // Tracks which owners confirmed each transaction

    /**
     * @notice Initializes the contract with a list of owners and a confirmation threshold.
     * @param _owners The list of initial owners.
     * @param _threshold The number of confirmations required for a transaction.
     */
    
    constructor(address[] memory _owners, uint256 _threshold) Ownable(msg.sender) {
    if (_owners.length == 0) revert InvalidThreshold();
    if (_threshold == 0 || _threshold > _owners.length) revert InvalidThreshold();

    for (uint256 i = 0; i < _owners.length; i++) {
        address owner = _owners[i];
        if (owner == address(0)) revert InvalidOwnerAddress();
        if (isOwner[owner]) revert OwnerNotUnique();

        isOwner[owner] = true;
        owners.push(owner);
    }

    threshold = _threshold;
}

    /**
     * @notice Allows the contract to receive Ether.
     */
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice Submits a new transaction for approval by the owners.
     * @param to The destination address of the transaction.
     * @param value The amount of Ether to send.
     * @param data The data payload (e.g., function call).
     * @return transactionId The ID of the newly created transaction.
     */
    function submitTransaction(
        address payable to,
        uint256 value,
        bytes memory data
    ) public onlyOwner returns (uint256 transactionId) {
        transactions.push(
            Transaction({
                to: to,
                value: value,
                data: data,
                executed: false,
                confirmations: 0
            })
        );
        transactionId = transactions.length - 1;
        emit TransactionSubmitted(transactionId);
    }

    /**
     * @notice Confirms a submitted transaction.
     * @param transactionId The ID of the transaction to confirm.
     */
    function confirmTransaction(uint256 transactionId) public onlyOwner {
        if (transactionId >= transactions.length) revert TransactionDoesNotExist();
        if (transactions[transactionId].executed) revert TransactionAlreadyExecuted();
        if (confirmations[transactionId][msg.sender]) revert TransactionAlreadyConfirmed();

        confirmations[transactionId][msg.sender] = true;
        transactions[transactionId].confirmations += 1;
        emit TransactionConfirmed(msg.sender, transactionId);

        if (transactions[transactionId].confirmations >= threshold) {
            executeTransaction(transactionId);
        }
    }

    /**
     * @notice Executes a confirmed transaction if it meets the required threshold.
     * @param transactionId The ID of the transaction to execute.
     */
    function executeTransaction(uint256 transactionId) public onlyOwner {
        if (transactionId >= transactions.length) revert TransactionDoesNotExist();
        if (transactions[transactionId].executed) revert TransactionAlreadyExecuted();

        Transaction storage txn = transactions[transactionId];
        
        if (txn.confirmations < threshold) revert NotEnoughConfirmations();

        txn.executed = true;

        (bool success, ) = txn.to.call{value: txn.value}(txn.data);

        if (!success) revert TransactionFailed();

        emit TransactionExecuted(transactionId);
    }

    /**
     * @notice Adds a new owner to the wallet. Only callable by existing owners.
     * @param newOwner The address of the new owner.
     */
    function addOwner(address newOwner) public onlyOwner {
        if (newOwner == address(0)) revert InvalidOwnerAddress();
        if (isOwner[newOwner]) revert OwnerNotUnique();

        isOwner[newOwner] = true;
        owners.push(newOwner);

        emit OwnerAdded(newOwner);
    }

    /**
     * @notice Removes an existing owner from the wallet. Only callable by existing owners.
     * @param ownerToRemove The address of the owner to remove.
     */
    function removeOwner(address ownerToRemove) public onlyOwner {
        if (!isOwner[ownerToRemove]) revert NotAnOwner();

        isOwner[ownerToRemove] = false;

        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == ownerToRemove) {
                owners[i] = owners[owners.length - 1];
                owners.pop();
                break;
            }
        }

        if (threshold > owners.length) {
            changeThreshold(owners.length); // Adjust threshold if necessary
        }

        emit OwnerRemoved(ownerToRemove);
    }

    /**
     * @notice Changes the confirmation threshold. Only callable by existing owners.
     * @param newThreshold The new confirmation threshold.
     */
    function changeThreshold(uint256 newThreshold) public onlyOwner {
        if (newThreshold == 0 || newThreshold > owners.length) revert InvalidThreshold();

        threshold = newThreshold;

        emit ThresholdChanged(newThreshold);
    }
}