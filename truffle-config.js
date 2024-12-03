const HDWalletProvider = require("@truffle/hdwallet-provider");
require("dotenv").config();

const RPC_URL_Alchemy_SEPOLIA = process.env.RPC_URL_Alchemy_SEPOLIA;
const Private_Key = process.env.GANACHE_PRIVATE_KEY;
const Etherscan_API_KEY = process.env.Etherscan_API_KEY;
const Coinmarketcap_API_KEY = process.env.Coinmarketcap_API_KEY;

module.exports = {
  networks: {
    development: {
      host: "172.28.128.1",
      port: 7545,
      network_id: "*",
    },
    hardhat: {
      chainId: 31337,
    },
    sepolia: {
      provider: () =>
        new HDWalletProvider(Private_Key, RPC_URL_Alchemy_SEPOLIA),
      network_id: 11155111,
      confirmations: 6,
      timeoutBlocks: 200,
      skipDryRun: true,
    },
  },

  migrations_directory: "./deploy",

  // Configure compiler
  compilers: {
    solc: {
      version: "0.8.27",
      settings: {
        optimizer: {
          enabled: true,
          runs: 200,
        },
      },
    },
  },

  // Mocha testing configuration
  mocha: {
    timeout: 1000000,
  },

  // Etherscan verification plugin configuration
  plugins: ["truffle-plugin-verify"],
  api_keys: {
    etherscan: Etherscan_API_KEY,
  },

  // Optional: Gas reporter configuration
  gasReporter: {
    enabled: true,
    currency: "USD",
    coinmarketcap: Coinmarketcap_API_KEY,
    token: "ETH",
    outputFile: "gas-reporter.txt",
    noColors: true,
  },
};
