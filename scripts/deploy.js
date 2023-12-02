// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
const nameWrapperApi = require("./abi/name-wrapper.json");
const nameWrapperDelegateAbi = require("./abi/name-wrapper-delegate.json");
const { namehash } = require("ethers");

async function deployEnsContracts() {

  const nameWrapperAddress = "0x114D4603199df73e7D157787f8778E21fCd13066";
  const controllerAddress = "0x280f3EdCDF23E5a645f55AdF143baAa177c214FB";
  const delegateAddress = "0x7112E8879f6236D2e1FA10e30Bb7151c471f12fd";
  // const namewrapperDelegate = await hre.ethers.deployContract("NameWrapperDelegate", [nameWrapperAddress, controllerAddress])

  const ethers = await hre.ethers;
  const signer = await ethers.getSigner(controllerAddress);

  const nameWrapper = new ethers.Contract(nameWrapperAddress, nameWrapperApi,  signer)
  const owner = await nameWrapper.ownerOf(namehash("nenad.eth"));
  const nameWrapperDelegate = new ethers.Contract(delegateAddress, nameWrapperDelegateAbi,  signer)

  console.log(owner)

  // const NameWrapperDelegate = await namewrapperDelegate.waitForDeployment();
  // const delegateAddress = await NameWrapperDelegate.getAddress();

  console.log("Name wrapper delegate deployed with address " + delegateAddress);

  const NamespaceEmitter = await hre.ethers.deployContract("NamespaceEmitter", [controllerAddress]);
  const emitter = await NamespaceEmitter.waitForDeployment();
  const emitterAddress = await emitter.getAddress();

  console.log("Emitter deployed on address" + emitterAddress);

  const NamespaceRegitry = await hre.ethers.deployContract("NamespaceRegistry", [controllerAddress, nameWrapperAddress, emitterAddress])
  const registry = await NamespaceRegitry.waitForDeployment();
  const registryAddress = await registry.getAddress();
  console.log("Registry deployed on address " + registryAddress);

  const NamespaceMinter = await hre.ethers.deployContract("NamespaceMinter", [controllerAddress, controllerAddress, controllerAddress, delegateAddress, emitterAddress, registryAddress]);
  const minter = await NamespaceMinter.waitForDeployment();

  const minterAddress = await minter.getAddress();

  console.log("Minter deployed on address " + minterAddress );

  await emitter.setController(minterAddress, true);
  await emitter.setController(registryAddress, true);
  const tx1 = await nameWrapperDelegate.setController(minterAddress, true);
  await tx1.wait();
  const tx = await nameWrapper.setApprovalForAll(delegateAddress, true);
  await tx.wait()
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
deployEnsContracts().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
