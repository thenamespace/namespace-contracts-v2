import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const VERIFIER = "0xEf2c32797724C2572D83Dd69E71c1A821e07FECa";
const TREASURY = "0xEf2c32797724C2572D83Dd69E71c1A821e07FECa";
const OWNER_ADDRESS = "0xEf2c32797724C2572D83Dd69E71c1A821e07FECa";

const NamespaceDeploymentModule = buildModule(
  "NamespaceDeploymentModule",
  (m) => {
    const namespaceDeployer = m.contract("NamespaceDeployer", [
      VERIFIER,
      TREASURY,
      OWNER_ADDRESS,
    ]);

    return { namespaceDeployer };
  }
);

export default NamespaceDeploymentModule;