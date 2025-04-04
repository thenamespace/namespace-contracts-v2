
import hre from "hardhat";

const ENS_REGISTRAR_CONTROLLER = "0xFED6a969AaA60E4961FCD3EBF1A2e8913ac65B72";
const OWNER_ADDRESS = "0x1D84ad46F1ec91b4Bb3208F645aD2fA7aBEc19f8";
const FEE_PERCENT = 2 * 10;

async function deploy() {
    const deployer = await hre.viem.deployContract("BulkNameRegistrar", [ENS_REGISTRAR_CONTROLLER, OWNER_ADDRESS, BigInt(FEE_PERCENT)])
    console.log(deployer.address, "registrar address")
}

deploy().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
