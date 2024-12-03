const { ethers } = require("hardhat");

async function main() {
  // Owner address for DEPLOYMENT
  const ownerAddress = "0xa4dfc410c271A41ab4CA6bB9a872a011BCF382c6";
  const stalePriceDelay = 3600; // Setting stale price delay to 1hr=3600sec

  // PriceOracle.sol Deployment script
  console.log("Deploying PriceOracle contract");
  console.log("-------------------SABR KARO-------------------");
  const PriceOracle = await ethers.getContractFactory("PriceOracle");
  const priceOracle = await PriceOracle.deploy(ownerAddress, stalePriceDelay);
  console.log(`PriceOracle deployed to: ${priceOracle.address}`);
  console.log("------------------------------------------------");

  // Setting Price Feeds for sepolia testnet tokens using latest chainlink Price Feed address

  const priceFeeds = [
    {
      token: "0x6B175474E89094C44Da98b954EedeAC495271d0F", // DAI ADDRESS
      feed: "0x14866185B1962B63C3Ea9E03Bc1da838bab34C19", //  DAI/USD CHAINLINK PRICE FEED
      decimals: 18, // DAI HAS 18 DECIMALS
    },

    {
      token: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2", // WETH ADDRESS
      feed: "0x694AA1769357215DE4FAC081bf1f309aDC325306", //  ETH/USD CHAINLINK PRICE FEED
      decimals: 18, // ETH HAS 18 DECIMALS
    },

    // WE CAN ADD MORE TOKENS AND PRICE FEED FROM: (ETHEREUM MAINNET OR SEPOLIA TESTNET)
  ];

  // NOW ADDING PRICE FEEDS TO THE CONTRACT
  for (let i = 0; i < priceFeeds.length; i++) {
    const { token, feed, decimals } = priceFeeds[i];
    console.log(`Setting price feed for token: ${token} with feed: ${feed}`);
    console.log("-------------------SABR KARO-------------------");
    await priceOracle.setPriceFeed(token, feed, decimals);
    console.log(`Pricefeed set sucessfully for ${token}`);
  }

  // Printing the final status
  console.log("Price feeds set sucessfully on PriceOracle Contract");
}

// Error handling
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
