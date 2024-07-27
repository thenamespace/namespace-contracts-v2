import hre from "hardhat";

const signer = "0x";
const owner = "0x";
const treasury = "0x";
const baseUri = ""

async function deploy() {
    const deployer = await hre.viem.deployContract("NamespaceL2Deployer", [signer, treasury, owner, baseUri])
    
    const controller = await deployer.read.controller();
    const resolver = await deployer.read.resolver();
    const manager = await deployer.read.registryResolver();
    const emitter = await deployer.read.emitter();

    console.log(deployer.address)

    console.log(`cont: ${controller}, resolver: ${resolver}, registryResolver: ${manager}, emitter: ${emitter}`)
}

deploy().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
