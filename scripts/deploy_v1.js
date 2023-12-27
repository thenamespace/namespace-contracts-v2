const hre = require("hardhat");

const verifier = "0xBd0a4cF87ac861594E072d4779805C4EE954001b";
const controller = "0x745b82391B5fE19235A86513ecaB61eB366536bD";
const treasury = "0xEF604aD7c0C94d2DFeab8d0BCBf45eB355F8b531";
const nameWrapper = "0x0635513f179D50A207757E05759CbD106d7dFcE8";

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
