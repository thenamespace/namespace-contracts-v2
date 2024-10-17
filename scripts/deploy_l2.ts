import hre from "hardhat";

const signer = "0xf4684693F4C78616C6a1391524280fC47C898DBe";
const treasury = "0x3E1e131E7e613D260F809E6BBE6Cbf7765EDC77f";
const baseUri = "https://metadata-api.namespace.tech/metadata/network/84532/token/"
const registryResolver = "0x8810B0A0946E1585Cb4ca0bB07fDC074d7038941"
const emitter = "0x8764EFC3d0b1172a3B76143b0A0E6757525Afc1f";
const resolver = "0x0a31201dc15E25062E4Be297a86F5AD8DccC8055";
const owner = "0x3E1e131E7e613D260F809E6BBE6Cbf7765EDC77f"

// address _verifier,
// address _treasury,
// string memory _baseUri,
// address _registryResolver,
// address _emitter,
// address _resolver,
// address _owner

//@ts-ignore
async function deploy() {
    const deployer = await hre.viem.deployContract("NamespaceL2DeployerV2", [signer, treasury, baseUri, registryResolver, emitter, resolver, owner])
    
    const controller = await deployer.read.controller();
    const tokenMetadata = await deployer.read.tokenMetadata();
    const proxy = await deployer.read.proxy();

    console.log(deployer.address)

    console.log(`cont: ${controller}, metadata: ${tokenMetadata}, proxy: ${proxy}`)
}

deploy().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
