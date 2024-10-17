import "@nomicfoundation/hardhat-toolbox-viem";
import { config as dotEnvConfig } from "dotenv";
import { HardhatUserConfig } from "hardhat/config";
import "solidity-coverage";
import { Hash } from "viem";

require("dotenv").config();

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: {
        enabled: true,
        runs: 100
      }
    }
  },
  networks: {
    sepolia: {
      url: process.env.SEPOLIA_RPC,
      chainId: 11155111,
      accounts: [process.env.TEST_WALLET_KEY as Hash],
    },
    base: {
      url: process.env.BASE_RPC,
      chainId: 8453,
      accounts: [process.env.BASE_WALLET_KEY as Hash],
    },
    baseSepolia: {
      url: "https://base-sepolia.g.alchemy.com/v2/kSLvIkdb8hKaBbTvK_5txOVuSgawItyv",
      chainId: 84532,
      accounts: [process.env.TEST_WALLET_KEY as Hash],
    },
  },
  mocha: {
    timeout: 100000000,
  },
  etherscan: {
    apiKey: process.env.BASESCAN_KEY,
  },
};

export default config;
