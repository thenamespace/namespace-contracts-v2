import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

/*
 yarn hardhat ignition deploy ignition/modules/test-l2.ts --network optimism
*/

export default buildModule("TestL2Deployment", (m) => {
  const testL2 = m.contract("TestL2");

  return { testL2 };
});
