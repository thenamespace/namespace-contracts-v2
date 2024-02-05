const hre = require("hardhat");

const signer = "";
const owner = "";
const url1 = ""

async function deploy() {
  const resolver = await hre.ethers.deployContract("OffchainResolver", [
    [url1],
    [signer],
    owner
  ]);

  await resolver.waitForDeployment();
  console.log(await resolver.getAddress() + " RESOLVER ADDRESS")
}

deploy().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
