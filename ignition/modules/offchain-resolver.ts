import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

/*
 yarn hardhat ignition deploy ignition/modules/offchain-resolver.ts --network sepolia --verify
*/

export default buildModule("OffchainResolverDeployment", (m) => {
  const resolver = m.contract("OffchainResolver", [
    [
      "https://ccip-gateway.namespace.tech/{sender}/{data}.json",
      // "https://gateway.namespace.tech/{sender}/{data}.json",
      // "https://gateway1.namespace.tech/{sender}/{data}.json",
      // "https://gateway2.namespace.tech/{sender}/{data}.json",
    ],
    ["0x740Bdb3D297F951AD44BEf7216Ddd2cdA339940b"],
    "0xb7B18611b8C51B4B3F400BaF09dB49E61e0aF044",
  ]);

  return { resolver };
});
