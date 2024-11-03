const { network, ethers } = require("hardhat");
const { developmentChain } = require("../helper-hardhat-config");
const { verify } = require("../utils/verify");

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deployer } = await getNamedAccounts();
  const { deploy, log } = deployments;
  const chainId = network.config.chainId;

  const TBA = await deployments.get("TokenboundAccount");
  console.log("TBA ", TBA.address);
  const Args = [TBA.address, 100, 3];

  const AdvancedGuardianRecovery = await deploy("AdvancedGuardianRecovery", {
    from: deployer,
    // in this contract, we can choose our initial price since it is a mock
    args: Args, // --> constructor args
    log: true,
    waitConfirmations: network.config.blockConfirmations || 1,
  });

  if (!developmentChain.includes(network.name)) {
    await verify(AdvancedGuardianRecovery.address, Args);
  }
  log("deploying the contract on the test network!!!!!");
  log("---------------------------------------------------");

  log("---------------------------------------------------");
  log("AdvancedGuardianRecovery Deployed!!!!!!!");
  log("---------------------------------------------------");
  log("---------------------------------------------------");
  log("---------------------------------------------------");
};

module.exports.tags = ["all", "AdvancedGuardianRecovery"];
