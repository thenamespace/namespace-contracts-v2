require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.20",
    settings: {
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
      chainId: 31337,
      allowUnlimitedContractSize: true,
      forking: {
        url: "https://eth-goerli.g.alchemy.com/v2/" + process.env.ALCHEMY_KEY,
        blockNumber: 9613399,
      },
    },
    sepolia: {
      url: "https://eth-sepolia.g.alchemy.com/v2/" + process.env.ALCHEMY_KEY,
      gasPrice: 14000000000,
      gas: 30_000_000,
      // blockGasLimit: 210000,
      chainId: 11155111,
      accounts: [process.env.ACCOUNT_KEY],
    },
    mainnet: {
      url: "https://eth-mainnet.g.alchemy.com/v2/" + process.env.ALCHEMY_KEY,
      // gasPrice: 31000000000,
      gas: 21_000_000,
      // blockGasLimit: 210000,
      chainId: 1,
      accounts: [process.env.ACCOUNT_KEY],
    },
  },
  mocha: {
    timeout: 100000000,
  },
  etherscan: {
    apiKey: "",
  },
};
