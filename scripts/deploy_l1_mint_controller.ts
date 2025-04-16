import hre from "hardhat";

const owner = "0xb7B18611b8C51B4B3F400BaF09dB49E61e0aF044";
const verifier = "0xf4684693F4C78616C6a1391524280fC47C898DBe"
const treasury = "0x9386Ede17239142F69657B6ce89c306657c62FEb";
const nameWrapper = "0xd4416b13d2b3a9abae7acd5d6c2bbdbe25686401"
const nameWrapperProxy = "0x25ADB7e69390FbfeEe26F3C8053955d4D4428Afd";
const publicResolver = "0x231b0Ee14048e9dCcD1d247744d114a4EB5E8E63";


// address _verifier,
// address _treasury,
// address _tokenMetadata,
// address _registryResolver,
// address _emitter,
// address _resolver,
// address _controllerProxy


//@ts-ignore
async function deploy() {
    const deployer = await hre.viem.deployContract("MintControllerDeployer", [owner, verifier, treasury, nameWrapper, nameWrapperProxy, publicResolver])
    
    const controller = await deployer.read.controller();
    console.log(`cont: ${controller}`)
}

deploy().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
