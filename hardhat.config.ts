import { HardhatUserConfig } from "hardhat/config";
import "hardhat-gas-reporter";
import "hardhat-contract-sizer";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-verify";
import "@typechain/hardhat";
import "solidity-coverage";

require("dotenv").config();

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.20",
    settings: {
      viaIR: true,
      optimizer: {
        enabled: true,
        runs: 1,
      },
      outputSelection: {
        "*": {
          "*": ["storageLayout"],
        },
      },
    },
  },
  networks: {
    hardhat: {
      chainId: 1337,
      allowUnlimitedContractSize: true,
      forking: {
        url:
          "https://eth-mainnet.g.alchemy.com/v2/" + process.env.L1_MAINNET_KEY,
        blockNumber: 19748904,
      },
    },
    sepolia: {
      url: "https://eth-sepolia.g.alchemy.com/v2/" + process.env.SEPOLIA_KEY,
      gasPrice: 60000000000,
      gas: 30_000_000,
      // blockGasLimit: 210000,
      chainId: 11155111,
      accounts: [process.env.ACCOUNT_KEY as string],
    },
    optimism_test: {
      url:
        "https://opt-sepolia.g.alchemy.com/v2/" + process.env.OPTIMISM_TEST_KEY,
      gasPrice: 60000000000,
      gas: 30_000_000,
      // blockGasLimit: 210000,
      chainId: 11155420,
      accounts: [process.env.ACCOUNT_KEY as string],
    },
    optimism: {
      url: "https://opt-mainnet.g.alchemy.com/v2/" + process.env.OPTIMISM_KEY,
      gasPrice: 60000000000,
      gas: 30_000_000,
      // blockGasLimit: 210000,
      chainId: 10,
      accounts: [process.env.ACCOUNT_KEY as string],
    },
    mainnet: {
      url: "https://eth-mainnet.g.alchemy.com/v2/" + process.env.L1_MAINNET_KEY,
      gasPrice: 9000000000,
      gas: 23_000_000,
      // blockGasLimit: 210000,
      chainId: 1,
      accounts: [process.env.ACCOUNT_KEY as string],
    },
  },
  mocha: {
    timeout: 100000000,
  },
  etherscan: {
    apiKey: "",
  },
};

export default config;
