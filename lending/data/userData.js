import { ethers } from 'ethers';
import {
  UiPoolDataProvider,
  UiIncentiveDataProvider,
  ChainId,
} from '@aave/contract-helpers';
import * as markets from '@bgd-labs/aave-address-book';
//import wallet connected


const provider = new ethers.providers.JsonRpcProvider(
  'https://your-rpc-url.com', // Update with Quranium's RPC
);

const currentAccount = 'user-account-address'; 

// Initialize Aave V3 contracts
const poolDataProviderContract = new UiPoolDataProvider({
  uiPoolDataProviderAddress: markets.AaveV3Ethereum.UI_POOL_DATA_PROVIDER,
  provider,
  chainId: ChainId.sepolia,  
});

const incentiveDataProviderContract = new UiIncentiveDataProvider({
  uiIncentiveDataProviderAddress:
    markets.AaveV3Ethereum.UI_INCENTIVE_DATA_PROVIDER,
  provider,
  chainId: ChainId.sepolia,  // Change chainId if using another network
});

async function fetchAaveData() {
  try {
    // Fetch all available reserves
    const reserves = await poolDataProviderContract.getUserReservesHumanized({
      lendingPoolAddressProvider: markets.AaveV3Ethereum.POOL_ADDRESSES_PROVIDER,
    });

    // Fetch user reserves based on their address
    const userReserves = await poolDataProviderContract.getUserReservesHumanized({
      lendingPoolAddressProvider: markets.AaveV3Ethereum.POOL_ADDRESSES_PROVIDER,
      user: currentAccount,
    });

    // Fetch available incentive data (APR, rewards)
    const reserveIncentives = await incentiveDataProviderContract.getReservesIncentivesDataHumanized({
      lendingPoolAddressProvider: markets.AaveV3Ethereum.POOL_ADDRESSES_PROVIDER,
    });

    // Fetch user-specific incentive data (rewards to claim)
    const userIncentives = await incentiveDataProviderContract.getUserReservesIncentivesDataHumanized({
      lendingPoolAddressProvider: markets.AaveV3Ethereum.POOL_ADDRESSES_PROVIDER,
      user: currentAccount,
    });

    
    console.log({ reserves, userReserves, reserveIncentives, userIncentives });
  } catch (error) {
    console.error("Error fetching Aave data", error);
  }
}

fetchAaveData();
