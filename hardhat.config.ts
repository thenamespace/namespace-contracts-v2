import "@nomicfoundation/hardhat-toolbox-viem";
import { HardhatUserConfig } from "hardhat/config";
import "solidity-coverage";
import { Hash } from "viem";
import { sepolia, base, mainnet } from "viem/chains"

require("dotenv").config();

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      },
      viaIR: true
    }
  },
  networks: {
    mainnet: {
      url: `https://eth-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_TOKEN}`,
      chainId: mainnet.id,
      accounts: [process.env.TEST_WALLET_KEY as Hash],
    },
    sepolia: {
      url: `https://eth-sepolia.g.alchemy.com/v2/${process.env.ALCHEMY_TOKEN}`,
      chainId: sepolia.id,
      accounts: [process.env.TEST_WALLET_KEY as Hash],
    },
    base: {
      url: `https://base-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_TOKEN}`,
      chainId: base.id,
      accounts: [process.env.BASE_WALLET_KEY as Hash],
    }
  },
  mocha: {
    timeout: 100000000,
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_KEY,
  },
};

export default config;
