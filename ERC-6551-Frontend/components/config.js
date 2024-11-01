import { createWalletClient, custom } from "viem";
import { sepolia } from "viem/chains";
import nftabi from "./nftabi.json";
import erc20abi from "./erc20abi.json";
import erc6551regAbi from "./erc6551registry.json";
import erc6551accAbi from "./erc6551account.json";
import { ethers } from "ethers";

const nftContractAddr = "0xa2269f4e04112043653b86741056f665310ba06a";
const erc6551RegistryAddr = "0xb0c4c48946718c9548e7275f0191d32e6cb3d0f6";
const erc6551BaseAccount = "0xe6b9d16cb2628c200e2cfc8ae19a6b3e25865c69";
const usdtContractAddr = "0xe4afc1092e98b9c838fbbe72cfb9fb8d97b3431e";

// Gas settings
const GAS_SETTINGS = {
  CREATE_ACCOUNT: 300000,
  SEND_CUSTOM: 200000,
  SEND_NATIVE: 100000,
};

const web3Provider = async () => {
  try {
    const [account] = await window.ethereum.request({
      method: "eth_requestAccounts",
    });
    const client = createWalletClient({
      account,
      chain: sepolia,
      transport: custom(window.ethereum),
    });
    return client;
  } catch (error) {
    console.error("Error connecting to Web3:", error);
    throw error;
  }
};

const convertToEth = async (type, value) => {
  try {
    if (type === "eth") {
      return Number(ethers.utils.formatEther(value)).toFixed(5);
    } else {
      return Number(ethers.utils.formatEther(value)).toFixed(2);
    }
  } catch (error) {
    console.error("Error converting value:", error);
    return "0.00";
  }
};

export async function connectWallet() {
  try {
    const connection = await web3Provider();
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const { chainId } = await provider.getNetwork();

    // Check if we're on Sepolia
    if (chainId !== 11155111) {
      throw new Error("Please connect to Sepolia network");
    }

    const signer = provider.getSigner();
    const nftcollection = new ethers.Contract(nftContractAddr, nftabi, signer);
    const erc6551registry = new ethers.Contract(
      erc6551RegistryAddr,
      erc6551regAbi,
      signer
    );
    const usdtContract = new ethers.Contract(
      usdtContractAddr,
      erc20abi,
      signer
    );

    return {
      connection,
      signer,
      provider,
      nftcollection,
      erc6551registry,
      usdtContract,
      chainId,
    };
  } catch (error) {
    console.error("Error in connectWallet:", error);
    throw error;
  }
}

async function getNftImageUrl(nftcid) {
  try {
    let cidurl = `https://ipfs.io/ipfs/${nftcid}/nft1.json`;
    let response = await fetch(cidurl);

    if (!response.ok) {
      throw new Error("Network response was not ok");
    }

    let output = await response.json();
    let imageurl = output.image.replace("ipfs://", "");
    return imageurl;
  } catch (error) {
    console.error("Error fetching NFT image URL:", error);
    return null;
  }
}

export async function getNftsInfo() {
  try {
    const web3connection = await connectWallet();
    const userwallet = web3connection.connection.account.address;
    const nftcollection = web3connection.nftcollection;
    const signer = web3connection.signer;
    const erc6551registry = web3connection.erc6551registry;
    const chainId = web3connection.chainId.toString();

    const nftinventory = await nftcollection.walletOfOwner(userwallet);
    const nftcid = (await nftcollection.baseURI()).replace("ipfs://", "");
    const imageurl = await getNftImageUrl(nftcid);

    const nftArray = await Promise.all(
      nftinventory.map(async (nftid) => {
        const nft6551wallet = await getErc6551Wallet(
          erc6551registry,
          chainId,
          nftid
        );
        const erc6551account = new ethers.Contract(
          nft6551wallet,
          erc6551accAbi,
          signer
        );

        const owner = await erc6551account
          .owner()
          .then(() => true)
          .catch(() => false);

        return {
          nftimage: imageurl,
          nftid: nftid.toString(),
          nftwallet: nft6551wallet,
          buttontext: owner ? "Withdraw" : "Create Account",
        };
      })
    );

    return nftArray;
  } catch (error) {
    console.error("Error in getNftsInfo:", error);
    throw error;
  }
}

async function getErc6551Wallet(erc6551registry, chainId, nftid) {
  try {
    const wallet = await erc6551registry.account(
      erc6551BaseAccount,
      chainId,
      nftContractAddr,
      nftid,
      0
    );
    return wallet;
  } catch (error) {
    console.error("Error getting ERC6551 wallet:", error);
    throw error;
  }
}

export async function getErc6551Balances(nft6551wallet) {
  try {
    const web3connection = await connectWallet();
    const provider = web3connection.provider;
    const usdtcontract = web3connection.usdtContract;

    const [nativebalanceraw, usdtbalanceraw] = await Promise.all([
      provider.getBalance(nft6551wallet),
      usdtcontract.balanceOf(nft6551wallet),
    ]);

    const [usdtbalance, nativebalance] = await Promise.all([
      convertToEth(null, usdtbalanceraw.toString()),
      convertToEth("eth", nativebalanceraw.toString()),
    ]);

    return [
      {
        nativebal: nativebalance,
        nativetoken: "ETH",
        custombal: usdtbalance,
        customtoken: "USDT",
      },
    ];
  } catch (error) {
    console.error("Error getting ERC6551 balances:", error);
    throw error;
  }
}

export async function walletAction(
  nft6551wallet,
  tokenname,
  appbuttontxt,
  nftid
) {
  try {
    const web3connection = await connectWallet();
    const provider = web3connection.provider;
    const erc6551registry = web3connection.erc6551registry;
    const { chainId } = await provider.getNetwork();

    if (appbuttontxt === "Create Account") {
      const gasEstimate = await erc6551registry.estimateGas.createAccount(
        erc6551BaseAccount,
        chainId,
        nftContractAddr,
        nftid,
        0,
        []
      );

      const tx = await erc6551registry.createAccount(
        erc6551BaseAccount,
        chainId,
        nftContractAddr,
        nftid,
        0,
        [],
        {
          gasLimit: Math.floor(gasEstimate.mul(120).div(100)), // Add 20% buffer
        }
      );

      await tx.wait();
      return true;
    } else {
      const userwallet = web3connection.connection.account.address;
      const signer = web3connection.signer;
      const usdtcontract = web3connection.usdtContract;
      const erc6551account = new ethers.Contract(
        nft6551wallet,
        erc6551accAbi,
        signer
      );

      if (tokenname === "USDT") {
        let usdtbalance = await usdtcontract.balanceOf(nft6551wallet);
        let withdraw = await erc6551account.sendCustom(
          userwallet,
          usdtbalance,
          usdtContractAddr,
          { gasLimit: GAS_SETTINGS.SEND_CUSTOM }
        );
        if (withdraw) {
          return true;
        }
      } else {
        let nativebalance = await provider.getBalance(nft6551wallet);
        let withdraw = await erc6551account.send(userwallet, nativebalance, {
          gasLimit: GAS_SETTINGS.SEND_NATIVE,
        });
        if (withdraw) {
          return true;
        }
      }
    }
  } catch (error) {
    console.error("Error in walletAction:", error);
    throw error;
  }
}
