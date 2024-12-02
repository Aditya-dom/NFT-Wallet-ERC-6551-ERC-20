const { ethers } = require("hardhat");

async function main() {
  // PriceOracle deployed contract address
  const priceOracleAddress = "0xf8adda5bec1Dc937a260EEA9bdF5380D04a95DaD";

  // Treasury Address where the execution fee will be sent
  const treasuryAddress = "0xa4dfc410c271A41ab4CA6bB9a872a011BCF382c6";

  // Setting Execution Fees
  const executionFee = ethers.utils.parseEther("0.001");

  // Max orders per user (Considering 10 orders per user)
  const maxOrdersPerUser = 10;

  // Owner Address
  const ownerAddress = "0xa4dfc410c271A41ab4CA6bB9a872a011BCF382c6";

  // Getiing Signers to deplot to the correct signer
  const [deployer] = await ethers.getSigners();

  console.log(`Deploying contracts with the account ${deployer.address}`);

  // Getting trading tools contract factory
  const TradingTools = await ethers.getContractFactory("TradingTools");

  // Now Deploying TradingTools Contract
  const tradingTools = await TradingTools.deploy(
    priceOracleAddress,
    treasuryAddress,
    executionFee,
    maxOrdersPerUser,
    ownerAddress
  );
  console.log("--------------------Deploying---------------------------");
  console.log(`TradingTools contract deployed to: ${tradingTools.address}`);
  await tradingTools.deployed();
  console.log("--------------------Deploying---------------------------");
  console.log("TradingTools contract is deployed and ready to interact!!!");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
