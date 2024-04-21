import "@nomicfoundation/hardhat-ignition-ethers";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-verify";
import "@typechain/hardhat";
import "hardhat-contract-sizer";
import "hardhat-gas-reporter";
import { HardhatUserConfig } from "hardhat/config";
import "solidity-coverage";

require("dotenv").config();

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.24",
    // settings: {
    //   viaIR: true,
    //   optimizer: {
    //     enabled: true,
    //     runs: 1,
    //   },
    //   outputSelection: {
    //     "*": {
    //       "*": ["storageLayout"],
    //     },
    //   },
    // },
  },
  networks: {
    hardhat: {
      chainId: 1337,
      allowUnlimitedContractSize: true,
      forking: {
        url: "https://eth-sepolia.g.alchemy.com/v2/" + process.env.ALCHEMY_KEY,
      },
    },
    sepolia: {
      url: "https://eth-sepolia.g.alchemy.com/v2/" + process.env.ALCHEMY_KEY,
      gasPrice: 60000000000,
      gas: 30_000_000,
      // blockGasLimit: 210000,
      chainId: 11155111,
      accounts: [process.env.ACCOUNT_KEY as string],
    },
    mainnet: {
      url: "https://eth-mainnet.g.alchemy.com/v2/" + process.env.ALCHEMY_KEY,
      gasPrice: 31000000000,
      gas: 30_000_000,
      // blockGasLimit: 210000,
      chainId: 1,
      accounts: [process.env.ACCOUNT_KEY as string],
    },
  },
  mocha: {
    timeout: 100000000,
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
};

export default config;
