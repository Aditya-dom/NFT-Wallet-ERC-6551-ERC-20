const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log(`Deploying contracts with account: ${deployer.address}`);

  // Deploying TradingToolsStorage
  const TradingToolsStorage = await ethers.getContractFactory(
    "TradingToolsStorage"
  );
  const tradingToolsStorage = await TradingToolsStorage.deploy();
  console.log("----------------------Deploying---------------------");
  await tradingToolsStorage.deployed();
  console.log(
    `TradingToolsStorage deployed to: ${tradingToolsStorage.address}`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
