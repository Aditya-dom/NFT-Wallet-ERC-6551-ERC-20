const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("AdvancedGuardianRecovery", function () {
    let TokenboundAccount, tokenboundAccount;
    let AdvancedGuardianRecovery, advancedGuardianRecovery;
    let owner, guardian1, guardian2, guardian3;
    let guardians;

    beforeEach(async function () {
        // Get signers
        [owner, guardian1, guardian2, guardian3] = await ethers.getSigners();

        // Deploy TokenboundAccount contract
        TokenboundAccount = await ethers.getContractFactory("TokenboundAccount");
        tokenboundAccount = await TokenboundAccount.deploy();
        await tokenboundAccount.deployed();

        // Set up guardians and threshold
        guardians = [guardian1.address, guardian2.address, guardian3.address];
        const guardianThreshold = 2; // Default threshold for tests
        const recoveryTimeLock = 60; // 1-minute time lock for quick tests

        // Deploy AdvancedGuardianRecovery contract
        AdvancedGuardianRecovery = await ethers.getContractFactory("AdvancedGuardianRecovery");
        advancedGuardianRecovery = await AdvancedGuardianRecovery.deploy(
            tokenboundAccount.address,
            guardians,
            guardianThreshold,
            recoveryTimeLock
        );
        await advancedGuardianRecovery.deployed();
    });

    it("should allow owner to add and remove guardians", async function () {
        await advancedGuardianRecovery.addGuardian(owner.address);
        expect(await advancedGuardianRecovery.isGuardian(owner.address)).to.be.true;

        await advancedGuardianRecovery.removeGuardian(owner.address);
        expect(await advancedGuardianRecovery.isGuardian(owner.address)).to.be.false;
    });

    it("should allow owner to update the guardian threshold", async function () {
        await advancedGuardianRecovery.updateThreshold(3);
        expect(await advancedGuardianRecovery.guardianThreshold()).to.equal(3);
    });

    it("should allow a guardian to initiate recovery", async function () {
        await advancedGuardianRecovery.connect(guardian1).initiateRecovery(owner.address);
        expect(await advancedGuardianRecovery.recoveryInProgress()).to.be.true;
        expect(await advancedGuardianRecovery.recoveryCandidate()).to.equal(owner.address);
    });

    it("should allow guardians to approve recovery and meet the threshold", async function () {
        await advancedGuardianRecovery.connect(guardian1).initiateRecovery(owner.address);
        await advancedGuardianRecovery.connect(guardian1).approveRecovery();
        await advancedGuardianRecovery.connect(guardian2).approveRecovery();

        // Check if the ownership of TokenboundAccount has been transferred
        expect(await tokenboundAccount.owner()).to.equal(owner.address);
        expect(await advancedGuardianRecovery.recoveryInProgress()).to.be.false;
    });

    it("should not complete recovery if approvals do not meet threshold", async function () {
        await advancedGuardianRecovery.connect(guardian1).initiateRecovery(owner.address);
        await advancedGuardianRecovery.connect(guardian1).approveRecovery();

        // Only one approval, so recovery should not be complete
        expect(await advancedGuardianRecovery.recoveryInProgress()).to.be.true;
        expect(await tokenboundAccount.owner()).not.to.equal(owner.address);
    });

    it("should allow the owner to cancel recovery", async function () {
        await advancedGuardianRecovery.connect(guardian1).initiateRecovery(owner.address);
        await advancedGuardianRecovery.connect(owner).cancelRecovery();

        expect(await advancedGuardianRecovery.recoveryInProgress()).to.be.false;
    });

    it("should allow the owner to activate and deactivate emergency stop", async function () {
        await advancedGuardianRecovery.connect(owner).activateEmergencyStop();
        expect(await advancedGuardianRecovery.recoveryPaused()).to.be.true;

        await advancedGuardianRecovery.connect(owner).deactivateEmergencyStop();
        expect(await advancedGuardianRecovery.recoveryPaused()).to.be.false;
    });

    it("should prevent recovery actions during emergency stop", async function () {
        await advancedGuardianRecovery.connect(owner).activateEmergencyStop();

        await expect(
            advancedGuardianRecovery.connect(guardian1).initiateRecovery(owner.address)
        ).to.be.revertedWith("Recovery is paused");

        await expect(
            advancedGuardianRecovery.connect(guardian1).approveRecovery()
        ).to.be.revertedWith("Recovery is paused");
    });

    it("should log the correct events during recovery process", async function () {
        await expect(advancedGuardianRecovery.connect(guardian1).initiateRecovery(owner.address))
            .to.emit(advancedGuardianRecovery, "RecoveryInitiated")
            .withArgs(owner.address, anyValue); // `anyValue` is a placeholder for the timestamp

        await expect(advancedGuardianRecovery.connect(guardian1).approveRecovery())
            .to.emit(advancedGuardianRecovery, "RecoveryApproved")
            .withArgs(guardian1.address);
    });

    it("should enforce time-locked recovery and allow veto by owner", async function () {
        const timeLock = await advancedGuardianRecovery.recoveryTimeLock();

        // Guardian initiates recovery
        await advancedGuardianRecovery.connect(guardian1).initiateRecovery(owner.address);
        
        // Approve recovery before time lock expires
        await expect(advancedGuardianRecovery.connect(guardian1).approveRecovery()).to.be.revertedWith("Recovery time lock active");

        // Fast-forward time to simulate the time lock expiry
        await ethers.provider.send("evm_increaseTime", [timeLock.toNumber()]);
        await ethers.provider.send("evm_mine", []);

        // After time lock, approval should work
        await advancedGuardianRecovery.connect(guardian1).approveRecovery();
        await advancedGuardianRecovery.connect(guardian2).approveRecovery();

        expect(await tokenboundAccount.owner()).to.equal(owner.address);
    });
});
