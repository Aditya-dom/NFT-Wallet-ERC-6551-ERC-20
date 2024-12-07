// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "./TokenboundAccount.sol"; // Reference to TBA

interface ITokenboundAccount {
    function transferController(address newController) external;
    function execute(address target, uint256 value, bytes calldata data) external returns (bytes memory);
}

contract AdvancedGuardianRecovery {
    event GuardianAdded(address indexed guardian);
    event GuardianRemoved(address indexed guardian);
    event RecoveryInitiated(uint256 startTime);
    event RecoveryApproved(address indexed guardian);
    event RecoveryCanceled(address indexed guardian);
    event EmergencyStopActivated(address indexed initiator);
    event RecoveryCompleted(address indexed newOwner);

    address public owner;
    address public tokenBoundAccount;
    bool public recoveryInProgress;
    uint256 public recoveryStartTime;
    uint256 public recoveryThreshold;
    uint256 public timeLockDuration;
    bool public emergencyStop;

    mapping(address => bool) public guardians;
    mapping(address => bool) public approvals;
    address[] public addressList; // List of addresses that have approved recovery
    uint256 public approvalCount;

    constructor(
        address _tokenBoundAccount,
        uint256 _timeLockDuration,
        uint256 _recoveryThreshold
    ) {
        owner = msg.sender;
        tokenBoundAccount = _tokenBoundAccount;
        timeLockDuration = _timeLockDuration;
        recoveryThreshold = _recoveryThreshold;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    modifier onlyGuardian() {
        require(guardians[msg.sender], "Caller is not a guardian");
        _;
    }

    modifier noEmergencyStop() {
        require(!emergencyStop, "Emergency stop activated");
        _;
    }

    function addGuardian(address guardian) external onlyOwner {
        guardians[guardian] = true;
        emit GuardianAdded(guardian);
    }

    function removeGuardian(address guardian) external onlyOwner {
        guardians[guardian] = false;
        emit GuardianRemoved(guardian);
    }

    function approveRecovery() external onlyGuardian noEmergencyStop {
        require(recoveryInProgress, "No recovery in progress");
        require(!approvals[msg.sender], "Guardian already approved");

        approvals[msg.sender] = true;
        addressList.push(msg.sender); // Add guardian to the address list
        approvalCount += 1;
        emit RecoveryApproved(msg.sender);

        if (approvalCount >= recoveryThreshold) {
            completeRecovery();
        }
    }

    function initiateRecovery() external onlyGuardian noEmergencyStop {
        require(!recoveryInProgress, "Recovery already in progress");
        recoveryInProgress = true;
        recoveryStartTime = block.timestamp;
        emit RecoveryInitiated(recoveryStartTime);
    }

    function vetoRecovery() external onlyOwner noEmergencyStop {
        require(recoveryInProgress, "No recovery in progress");
        recoveryInProgress = false;
        resetApprovals();
        emit RecoveryCanceled(msg.sender);
    }

    function activateEmergencyStop() external onlyOwner {
        emergencyStop = true;
        emit EmergencyStopActivated(msg.sender);
    }

    function completeRecovery() internal {
        require(
            recoveryInProgress && (block.timestamp >= recoveryStartTime + timeLockDuration),
            "Recovery time lock not passed"
        );

        recoveryInProgress = false;
        resetApprovals();
        ITokenboundAccount(tokenBoundAccount).transferController(owner);
        emit RecoveryCompleted(owner);
    }

    function resetApprovals() internal {
        for (uint256 i = 0; i < addressList.length; i++) {
            approvals[addressList[i]] = false;
        }
        delete addressList; // Clear the address list after resetting
        approvalCount = 0;
    }

    function executeAsOwner(
        address target,
        uint256 value,
        bytes calldata data
    ) external onlyOwner noEmergencyStop returns (bytes memory) {
        return ITokenboundAccount(tokenBoundAccount).execute(target, value, data);
    }
}