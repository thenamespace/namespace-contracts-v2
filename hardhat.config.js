require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.20",
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
    networks: {
      goerli:  {
        url: "https://goerli.infura.io/v3/dd7b1fa841f04b9d9a985f5345608bbc",
        gasPrice: 125000000000,
        gas: 21_000_000,
        // blockGasLimit: 210000,
        chainId: 5,
        accounts: ["97d6b7f1238842aaa5ee9a39d3e5671bde52e61dfa8242139b87948e56af5bda"],
      },
    }
  },
}
