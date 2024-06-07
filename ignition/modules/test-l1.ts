import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

/*
 yarn hardhat ignition deploy ignition/modules/test-l1.ts --network sepolia
*/

export default buildModule("TestL1Deployment", (m) => {
  const testL1 = m.contract("TestL1", [
    "0x8CeA85eC7f3D314c4d144e34F2206C8Ac0bbadA1", // verifier localhost
    "0x81888190D601696BA9e2D94a90d631E886fDFF99", // L2 contract mainnet
    // "0x0c69EB258484C54066739b88EBA349951347cF53", // sepolia verifier
    // "0x2A338C586D7aD075B18884270CA0B501a14490D9", // L2 contract testnet
  ]);

  return { testL1 };
});
