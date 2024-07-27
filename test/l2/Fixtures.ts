import hre from "hardhat";
import { Hash, namehash, parseEther, toHex } from "viem";
import {
  FactoryContext,
  generateFactoryContextSignature,
  generateMintContextSignature,
  MintContext,
  randomNonce,
} from "./SignaturesHelper";
import { privateKeyToAccount } from "viem/accounts";

export const BASE_URI = "https://dummy-base-uri/";
export const ENS_NAME = "namespace.eth";
export const NAME_NODE = namehash(ENS_NAME);
export const ONE_YEAR_EXPIRY_SECONDS = 365 * 24 * 60 * 60;

export async function controllerFullFlowFixture() {
  // Contracts are deployed using the first signer/account by default
  const [wallet01, wallet02] = await hre.viem.getWalletClients();

  const verifier01 = privateKeyToAccount(process.env.TEST_VERIFIER as Hash);

  const treasury = wallet02;
  const owner = wallet01;

  // Deployer Controller and Manager
  const emitter = await hre.viem.deployContract("RegistryEmitter");
  const nodeResolver = await hre.viem.deployContract("NodeRegistryResolver", []);
  const resolver = await hre.viem.deployContract("NamePublicResolver", [
    nodeResolver.address,
  ]);

  const controller = await hre.viem.deployContract("NameRegistryController", [
    verifier01.address,
    treasury.account.address,
    BASE_URI,
    nodeResolver.address,
    emitter.address,
    resolver.address
  ]);

  const pc = await hre.viem.getPublicClient();
  const tx01 = await nodeResolver.write.setController([controller.address, true]);

  const tx001 = await emitter.write.setController([controller.address, true]);

  await pc.waitForTransactionReceipt({ hash: tx01 });
  await pc.waitForTransactionReceipt({ hash: tx001 });

  // Deploy new EnsRegistrarContract
  const factoryContext: FactoryContext = {
    expirableType: 0,
    tokenName: "Namespace",
    owner: wallet01.account.address,
    parentControl: 0,
    label: ENS_NAME.split(".")[0],
    TLD: ENS_NAME.split(".")[1],
    tokenSymbol: "NS",
  };

  const chainId = await pc.getChainId();

  const signature = await generateFactoryContextSignature(
    factoryContext,
    verifier01,
    chainId,
    controller.address
  );

  const tx02 = await controller.write.deploy([factoryContext, signature]);
  await pc.waitForTransactionReceipt({ hash: tx02 });

  const deployEvent = await controller.getEvents.RegistryDeployed();
  const registrarAddress = deployEvent[0].args.registryAddress;

  const mintFee = BigInt(parseEther("0.1", "wei"));
  const mintPrice = BigInt(parseEther("1", "wei"));

  const mintRequest: MintContext = {
    expiry: BigInt(0),
    fee: mintFee,
    label: "testing",
    owner: owner.account.address,
    parentNode: namehash(`${factoryContext.label}.${factoryContext.TLD}`),
    paymentReceiver: owner.account.address,
    price: mintPrice,
    nonce: randomNonce()
  };

  const mintSignature = await generateMintContextSignature(
    mintRequest,
    verifier01,
    chainId,
    controller.address
  );

  const tx03 = await controller.write.mint(
    [mintRequest, mintSignature, [], toHex("test")],
    {
      value: mintFee + mintPrice,
    }
  );

  await pc.waitForTransactionReceipt({ hash: tx03 });

  const registry = await hre.viem.getContractAt(
    //@ts-ignore
    "EnsNameRegistry",
    registrarAddress
  );

  return {
    controller,
    nodeResolver,
    registry,
    verifier: verifier01,
    treasury,
    owner: owner,
    publicClient: pc,
    chainId: chainId,
    factoryContext,
    mintRequest,
    resolver,
  };
}
