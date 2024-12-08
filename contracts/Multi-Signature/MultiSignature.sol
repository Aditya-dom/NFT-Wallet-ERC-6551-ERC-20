//SPDX-LICENSE-IDENTIFIER: MIT
pragma solidity >=0.7.0 <0.9.0;

import {QMath} from "contracts/Common/QMath.sol";

/**
 * @author Meet Jain - @meetjn
 * @title MultiSignature - A multi signature wallet with support for confirmations using signed messages based on EIP-712.
 * @dev A simplified multi-signature wallet contract that allows multiple owners to approve transactions.
 *      Transactions require a minimum number of approvals (threshold) to be executed.
 * 
 *      Most important concepts:
 *      - Threshold: Number of required confirmations for a Q-NFT-Wallet transaction.
 *      - Owners: List of addresses that control the Q-NFT-Wallet. They are the only ones that can add/remove owners, change the threshold and
 *        approve transactions. Managed in `OwnerManager`.
 *      - Signature: A valid signature of an owner of the Q-NFT-Wallet for a transaction hash.
 */

contract MultiSigWallet {
    using QMath for uint256;

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
     * @dev Modifier to restrict access to only wallet owners.
     */
    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not an owner");
        _;
    }

    /**
     * @dev Modifier to check if a transaction exists.
     * @param transactionId The ID of the transaction.
     */
    modifier transactionExists(uint256 transactionId) {
        require(transactionId < transactions.length, "Transaction does not exist");
        _;
    }

    /**
     * @dev Modifier to check if a transaction has not been executed yet.
     * @param transactionId The ID of the transaction.
     */
    modifier notExecuted(uint256 transactionId) {
        require(!transactions[transactionId].executed, "Transaction already executed");
        _;
    }

    /**
     * @dev Modifier to check if a transaction has not been confirmed by the sender yet.
     * @param transactionId The ID of the transaction.
     */
    modifier notConfirmed(uint256 transactionId) {
        require(!confirmations[transactionId][msg.sender], "Transaction already confirmed by this owner");
        _;
    }

    /**
     * @notice Initializes the contract with a list of owners and a confirmation threshold.
     * @param _owners The list of initial owners.
     * @param _threshold The number of confirmations required for a transaction.
     */
    constructor(address[] memory _owners, uint256 _threshold) {
        require(_owners.length > 0, "Owners required");
        require(_threshold > 0 && _threshold <= _owners.length, "Invalid threshold");

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid owner");
            require(!isOwner[owner], "Owner not unique");

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
    function submitTransaction(address payable to, uint256 value, bytes memory data)
        public
        onlyOwner
        returns (uint256 transactionId)
    {
        transactions.push(Transaction({
            to: to,
            value: value,
            data: data,
            executed: false,
            confirmations: 0
        }));
        transactionId = transactions.length - 1;
        emit TransactionSubmitted(transactionId);
    }

    /**
     * @notice Confirms a submitted transaction.
     * @param transactionId The ID of the transaction to confirm.
     */
    function confirmTransaction(uint256 transactionId)
        public
        onlyOwner
        transactionExists(transactionId)
        notExecuted(transactionId)
        notConfirmed(transactionId)
    {
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
    function executeTransaction(uint256 transactionId)
        public
        onlyOwner
        transactionExists(transactionId)
        notExecuted(transactionId)
    {
        Transaction storage txn = transactions[transactionId];
        
        require(txn.confirmations >= threshold, "Not enough confirmations");

        txn.executed = true;
        
        (bool success,) = txn.to.call{value: txn.value}(txn.data);
        
        require(success, "Transaction failed");
        
        emit TransactionExecuted(transactionId);
    }

    /**
     * @notice Adds a new owner to the wallet. Only callable by existing owners.
     * @param newOwner The address of the new owner.
     */
    function addOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid owner address");
        require(!isOwner[newOwner], "Already an owner");

        isOwner[newOwner] = true;
        owners.push(newOwner);

        emit OwnerAdded(newOwner);
    }

    /**
     * @notice Removes an existing owner from the wallet. Only callable by existing owners.
     * @param ownerToRemove The address of the owner to remove.
     */
    function removeOwner(address ownerToRemove) public onlyOwner {
        require(isOwner[ownerToRemove], "Not an owner");

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
        require(newThreshold > 0 && newThreshold <= owners.length, "Invalid threshold");
        
        threshold = newThreshold;

        emit ThresholdChanged(newThreshold);
    }
}
