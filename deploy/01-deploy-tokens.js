const { network, ethers } = require("hardhat");
const { developmentChain } = require("../helper-hardhat-config");
const { verify } = require("../utils/verify");

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deployer } = await getNamedAccounts();
  const { deploy, log } = deployments;
  const chainId = network.config.chainId;

    
  const accounts = await ethers.getSigners();
  const User = accounts[1];
  const userArgs = [User.address];

  const USDT = await deploy("USDT", {
    from: deployer,
    // in this contract, we can choose our initial price since it is a mock
    args: [User.address], // --> constructor args
    log: true,
    waitConfirmations: network.config.blockConfirmations || 1,
  });

  if (!developmentChain.includes(network.name)) {
    await verify(USDT.address, User.address);
  }
  log("deploying the contract on the test network!!!!!");
  log("---------------------------------------------------");

  log("----------------------------------------------");
  log("USDT Deployed!!!!!!!");
  log("-----------------------------------------------");
  log("-----------------------------------------------");
  log("-----------------------------------------------");  


    const NFTCollection = await deploy("Collection", {
      from: deployer,
      // in this contract, we can choose our initial price since it is a mock
      args: [User.address], // --> constructor args
      log: true,
      waitConfirmations: network.config.blockConfirmations || 1,
    });

    if (!developmentChain.includes(network.name)) {
      await verify(NFTCollection.address, User.address);
    }
    log("deploying the contract on the test network!!!!!");
    log("---------------------------------------------------");

    log("----------------------------------------------");
    log("NFTCollection Deployed!!!!!!!");
    log("-----------------------------------------------");
    log("-----------------------------------------------");
    log("-----------------------------------------------");  
};

module.exports.tags = ["all", "USDT_COlllection"];
