import { BigNumber, ethers, providers } from 'ethers';
const { Pool, EthereumTransactionTypeExtended } = require('@aave/contract-helpers');
const markets = require('@bgd-labs/aave-address-book');

const provider = new ethers.providers.JsonRpcProvider(
'RPC'
);


const pool = new Pool(provider, {
  POOL: markets.AaveV3Ethereum.POOL,
});

async function submitTransaction({ provider, tx }) {
  if (!(tx instanceof EthereumTransactionTypeExtended)) {
    throw new Error('Invalid transaction type');
  }
  
  const extendedTxData = await tx.tx();
  const { from, ...txData } = extendedTxData;
  const signer = provider.getSigner(from); 
  const txResponse = await signer.sendTransaction({
    ...txData,
    value: txData.value ? BigNumber.from(txData.value) : undefined,
  });
  return txResponse;
}

module.exports = { submitTransaction };