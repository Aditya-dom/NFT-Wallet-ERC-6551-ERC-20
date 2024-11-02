const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();

    const TokenboundAccount = await hre.ethers.getContractFactory("TokenboundAccount");
    const tokenboundAccount = await TokenboundAccount.deploy();
    await tokenboundAccount.deployed();
    console.log("TokenboundAccount deployed to:", tokenboundAccount.address);

    const AdvancedGuardianRecovery = await hre.ethers.getContractFactory("AdvancedGuardianRecovery");
    const timeLockDuration = 86400; // 1 day in seconds
    const recoveryThreshold = 2; // Set the threshold as per requirement

    const advancedGuardianRecovery = await AdvancedGuardianRecovery.deploy(
        tokenboundAccount.address,
        timeLockDuration,
        recoveryThreshold
    );
    await advancedGuardianRecovery.deployed();
    console.log("AdvancedGuardianRecovery deployed to:", advancedGuardianRecovery.address);

    await tokenboundAccount.transferController(advancedGuardianRecovery.address);
    console.log("AdvancedGuardianRecovery set as controller for TokenboundAccount");
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});