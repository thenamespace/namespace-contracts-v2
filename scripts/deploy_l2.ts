import hre from "hardhat";

const signer = "0xf4684693F4C78616C6a1391524280fC47C898DBe";
const treasury = "0x81674d005C55Eb1D573e8a9C06d4041723F42c58";
const registryResolver = "0x0D8e2772B4D8d58C8a66EEc5bf77c07934b84942"
const emitter = "0xA9EA3fbBDB2d1696dC67C5FA45D9A64Ac432888C";
const resolver = "0x32d63B83BBA5a25f1f8aE308d7fd1F3c0b1abfA6";
const owner = "0x81674d005C55Eb1D573e8a9C06d4041723F42c58"
const tokenMetadata = "0xD3EfFd65935e67559914496d34fe5c4F49306891"
const contProxy = "0x9D3A8D587F1A3eFd194f8aDCfE964C3b244b763D"

// address _verifier,
// address _treasury,
// address _tokenMetadata,
// address _registryResolver,
// address _emitter,
// address _resolver,
// address _controllerProxy


//@ts-ignore
async function deploy() {
    const deployer = await hre.viem.deployContract("NamespaceL2DeployerV2", [signer, treasury, registryResolver, emitter, resolver, owner, contProxy, tokenMetadata])
    
    const controller = await deployer.read.controller();


    console.log(deployer.address)

    console.log(`cont: ${controller}`)
}

deploy().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
