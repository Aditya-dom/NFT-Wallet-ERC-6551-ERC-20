const { network, ethers } = require("hardhat");
const { developmentChain } = require("../helper-hardhat-config");
const { verify } = require("../utils/verify");

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deployer } = await getNamedAccounts();
  const { deploy, log } = deployments;
  const chainId = network.config.chainId;

  const args = []

  const ERC6551Registry = await deploy("ERC6551Registry", {
    from: deployer,
    // in this contract, we can choose our initial price since it is a mock
    args: args, // --> constructor args
    log: true,
    waitConfirmations: network.config.blockConfirmations || 1,
  });

  if (
    !developmentChain.includes(network.name)
  ) {
    await verify(ERC6551Registry.address, args);
  }
  log("deploying the contract on the test network!!!!!");
  log("---------------------------------------------------");

  log("----------------------------------------------");
  log("ERC6551Registry Deployed!!!!!!!");
  log("-----------------------------------------------");
  log("-----------------------------------------------");
  log("-----------------------------------------------");

  
};

module.exports.tags = ["all", "Registery_Contract"];
