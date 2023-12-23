// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function deployContractsGoerli() {
  const nameWrapperAddress = "";
  const verifierAddress = "";
  const controllerAddress = "";
  const treasuryAddress = "";

  const NamespaceRegistry = await hre.ethers.deployContract("NamespaceRegistry", [controllerAddress]);

  const deployedRegistry = await NamespaceRegistry.waitForDeployment();
  const registryAddress = await deployedRegistry.getAddress();

  console.log(registryAddress, " Namespace registry address");

  const NamespaceOperations = await hre.ethers.deployContract("NamespaceOperations", [verifierAddress, treasuryAddress, controllerAddress, nameWrapperAddress, registryAddress]);
  const deployedOps = await NamespaceOperations.waitForDeployment();
  const opsAddress = await deployedOps.getAddress();

  console.log(opsAddress, " Namespace ops address");

  const tx = await deployedRegistry.setController(opsAddress, true);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
deployContractsGoerli().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
