// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./TokenboundAccount.sol"; // Reference to TBA

contract AdvancedGuardianRecovery {
    address public owner;
    address[] public guardians;
    mapping(address => bool) public isGuardian;
    mapping(address => bool) public hasApproved;
    uint256 public guardianThreshold;
    uint256 public recoveryTimeLock;
    uint256 public recoveryInitiatedTime;
    address public recoveryCandidate;
    bool public recoveryInProgress;
    bool public recoveryPaused;

    TokenboundAccount public tokenboundAccount;

    event GuardianAdded(address indexed guardian);
    event GuardianRemoved(address indexed guardian);
    event RecoveryInitiated(address indexed candidate, uint256 timestamp);
    event RecoveryApproved(address indexed guardian);
    event RecoveryCompleted(address indexed newOwner);
    event RecoveryCancelled();
    event EmergencyStopActivated();

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    modifier onlyGuardian() {
        require(isGuardian[msg.sender], "Caller is not a guardian");
        _;
    }

    modifier recoveryLock() {
        require(!recoveryPaused, "Recovery is paused");
        require(
            !recoveryInProgress || 
            (block.timestamp >= recoveryInitiatedTime + recoveryTimeLock), 
            "Recovery time lock active"
        );
        _;
    }

    constructor(
        address _tokenboundAccount,
        address[] memory _guardians,
        uint256 _guardianThreshold,
        uint256 _recoveryTimeLock
    ) {
        require(_guardians.length >= _guardianThreshold, "Threshold exceeds guardian count");
        owner = msg.sender;
        guardians = _guardians;
        guardianThreshold = _guardianThreshold;
        recoveryTimeLock = _recoveryTimeLock;
        tokenboundAccount = TokenboundAccount(_tokenboundAccount);

        for (uint256 i = 0; i < _guardians.length; i++) {
            isGuardian[_guardians[i]] = true;
            emit GuardianAdded(_guardians[i]);
        }
    }

    function addGuardian(address _guardian) external onlyOwner {
        require(!isGuardian[_guardian], "Already a guardian");
        guardians.push(_guardian);
        isGuardian[_guardian] = true;
        emit GuardianAdded(_guardian);
    }

    function removeGuardian(address _guardian) external onlyOwner {
        require(isGuardian[_guardian], "Not a guardian");
        isGuardian[_guardian] = false;

        // Remove guardian from approval tracking to avoid stale data
        if (hasApproved[_guardian]) {
            hasApproved[_guardian] = false;
        }

        emit GuardianRemoved(_guardian);
    }

    function updateThreshold(uint256 _newThreshold) external onlyOwner {
        require(_newThreshold <= guardians.length, "Threshold exceeds guardian count");
        guardianThreshold = _newThreshold;
    }

    function initiateRecovery(address newOwner) external onlyGuardian recoveryLock {
        require(newOwner != address(0), "Invalid recovery candidate");
        require(recoveryCandidate == newOwner || recoveryCandidate == address(0), "Recovery already in progress");

        recoveryInProgress = true;
        recoveryCandidate = newOwner;
        recoveryInitiatedTime = block.timestamp;

        emit RecoveryInitiated(newOwner, block.timestamp);
    }

    function approveRecovery() external onlyGuardian recoveryLock {
        require(recoveryInProgress, "No recovery in progress");
        require(!hasApproved[msg.sender], "Guardian has already approved");

        hasApproved[msg.sender] = true;
        emit RecoveryApproved(msg.sender);

        if (getApprovalCount() >= guardianThreshold) {
            completeRecovery();
        }
    }

    function completeRecovery() internal {
        require(recoveryInProgress, "No recovery in progress");
        require(getApprovalCount() >= guardianThreshold, "Not enough approvals");

        tokenboundAccount.transferOwnership(recoveryCandidate);
        emit RecoveryCompleted(recoveryCandidate);

        // Reset recovery state
        resetRecovery();
    }

    function cancelRecovery() external onlyOwner {
        require(recoveryInProgress, "No recovery in progress");
        resetRecovery();
        emit RecoveryCancelled();
    }

    function activateEmergencyStop() external onlyOwner {
        recoveryPaused = true;
        emit EmergencyStopActivated();
    }

    function deactivateEmergencyStop() external onlyOwner {
        recoveryPaused = false;
    }

    function resetRecovery() internal {
        recoveryInProgress = false;
        recoveryCandidate = address(0);
        recoveryInitiatedTime = 0;

        for (uint256 i = 0; i < guardians.length; i++) {
            hasApproved[guardians[i]] = false;
        }
    }

    function getApprovalCount() public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < guardians.length; i++) {
            if (hasApproved[guardians[i]]) {
                count++;
            }
        }
        return count;
    }
}