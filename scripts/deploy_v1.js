const hre = require("hardhat");

const verifier = "";
const controller = "";
const treasury = "";
const nameWrapper = "";

async function deploy() {
  const deployer = await hre.ethers.deployContract("NamespaceDeployer", [
    verifier,
    treasury,
    controller,
    nameWrapper,
  ]);

  await deployer.waitForDeployment();
  console.log("Minter address " + await deployer.minting());
  console.log("Lister address " + await deployer.listing());
  console.log("NameWrapperDelegate address " + await deployer.nameWrapperDelegate())
}

deploy().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
