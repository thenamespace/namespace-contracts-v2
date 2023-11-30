// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {

  const currentTimestampInSeconds = Math.round(Date.now() / 1000);
  const unlockTime = currentTimestampInSeconds + 60;

  const validator = await hre.ethers.deployContract("")

  const lockedAmount = hre.ethers.parseEther("0.001");

  const lock = await hre.ethers.deployContract("Lock", [unlockTime], {
    value: lockedAmount,
  });

  await lock.waitForDeployment();

  console.log(
    `Lock with ${ethers.formatEther(
      lockedAmount
    )}ETH and unlock timestamp ${unlockTime} deployed to ${lock.target}`
  );
}

async function deployEnsContracts() {
  const nameWrapperAddress = "0x114D4603199df73e7D157787f8778E21fCd13066";
  const controllerAddress = "0x280f3EdCDF23E5a645f55AdF143baAa177c214FB";
  const namewrapperDelegate = await hre.ethers.deployContract("NameWrapperDelegate", [nameWrapperAddress, controllerAddress])

  const NameWrapperDelegate = await namewrapperDelegate.deployed();
  const delegateAddress = NameWrapperDelegate.address;

  console.log("Name wrapper delegate deployed with address " + delegateAddress);

  const NamespaceEmitter = await hre.ethers.deployContract("NamespaceEmitter", [controllerAddress]);
  const emitter = await NamespaceEmitter.deployed();
  const emitterAddress = await emitter.address;

  console.log("Emitter deployed on address" + emitterAddress);

  // address _verifier,
  // address _treasury,
  // address _controller,
  // INameWrapper _wrapperDelegate

  const NamespaceMinter = await hre.ethers.deployContract("NamespaceMinter", [controllerAddress, controllerAddress, controllerAddress, delegateAddress, emitterAddress]);
  const minter = await NamespaceMinter.deployed();

  console.log("Minter has been deployed on address " + minter.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
