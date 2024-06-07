import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

/*
 yarn hardhat ignition deploy ignition/modules/op-verifier.ts --network sepolia --verify
*/

export default buildModule("OpVerifierDeployment", (m) => {
  const verifier = m.contract("OPVerifier", [
    ["http://localhost:3000/resolve/{sender}/{data}.json"],
    // "0x90E9c4f8a994a250F6aEfd61CAFb4F2e895D458F", // L2OutputOracle sepolia
    "0xdfe97868233d1aa22e815a266982f2cf17685a27", // L2OutputOracle mainnet
  ]);

  return { verifier };
});
