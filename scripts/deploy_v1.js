const hre = require("hardhat");

const verifier = "0x3d2fcA5C6D40cbB8c2A93A0a8525a29865D596a9";
const controller = "0x3E1e131E7e613D260F809E6BBE6Cbf7765EDC77f";
const treasury = "0x0B31EB15d388d2345902ac5a126f60b43F7B93b7";
const nameWrapper = "0x0635513f179D50A207757E05759CbD106d7dFcE8";
const reverseRegistrar = "0xA0a1AbcDAe1a2a4A2EF8e9113Ff0e02DD81DC0C6"
const minterVersion = "1";

async function deploy() {
  const deployer = await hre.ethers.deployContract("NamespaceDeployer", [
    verifier,
    treasury,
    controller,
    nameWrapper,
    reverseRegistrar,
    minterVersion
  ]);

  console.log(deployer, "DEPLOYER")
  await deployer.waitForDeployment();
  console.log("Minter address " + await deployer.minting());
  console.log("Lister address " + await deployer.listing());
  console.log("NameWrapperDelegate address " + await deployer.nameWrapperDelegate());
  console.log("Lister address " + await deployer.test());
}

deploy().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
