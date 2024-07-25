import hre from "hardhat";

const signer = "0xf4684693F4C78616C6a1391524280fC47C898DBe";
const owner = "0x81674d005C55Eb1D573e8a9C06d4041723F42c58";
const treasury = "0x81674d005C55Eb1D573e8a9C06d4041723F42c58";
const baseUri = "https://metadata.namespace.tech/network/8453/token/"

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
