import { loadFixture, time } from "@nomicfoundation/hardhat-network-helpers";
import {
  controllerFullFlowFixture,
  NAME_NODE,
  ONE_YEAR_EXPIRY_SECONDS,
} from "./Fixtures";
import { expect } from "chai";
import {
  encodeFunctionData,
  Hash,
  namehash,
  parseAbi,
  parseEther,
  toHex,
  zeroAddress,
} from "viem";
import {
  ExtendExpiryContext,
  FactoryContext,
  generateExtendExpiryContextSignature,
  generateFactoryContextSignature,
  generateMintContextSignature,
  MintContext,
  randomNonce,
} from "./SignaturesHelper";
import hre from "hardhat";

describe("NameRegistrarController", () => {
  describe("Minting", () => {
    it("Should mint a subname nft with proper parameters", async () => {
      const { controller, mintRequest, factoryContext, nodeResolver } =
        await loadFixture(controllerFullFlowFixture);

      const mintEvents = await controller.getEvents.NameMinted();
      expect(mintEvents.length).to.equal(1);
      const event = mintEvents[0];

      expect(event.args.label).to.equal(mintRequest.label);
      expect(event.args.price).to.equal(mintRequest.price);
      expect(event.args.fee).to.equal(mintRequest.fee);
      expect(event.args.owner?.toLocaleLowerCase()).to.equal(
        mintRequest.owner.toLocaleLowerCase()
      );

      const fullSubname = `${mintRequest.label}.${factoryContext.label}.${factoryContext.TLD}`;
      const node = namehash(fullSubname);

      const registryAddr = await nodeResolver.read.nodeRegistries([
        namehash(`${factoryContext.label}.${factoryContext.TLD}`),
      ]);

      const nameRegistry = await hre.viem.getContractAt(
        "EnsNameRegistry",
        registryAddr
      );

      const subnameRegistrarOwner = await nameRegistry.read.ownerOf([
        BigInt(node),
      ]);

      expect(subnameRegistrarOwner.toLocaleLowerCase()).to.equal(
        mintRequest.owner.toLocaleLowerCase()
      );
    });

    it("Should mint subname with resolver data", async () => {
      const {
        controller,
        resolver,
        factoryContext,
        owner,
        verifier,
        chainId,
        publicClient,
        nodeResolver,
      } = await loadFixture(controllerFullFlowFixture);

      const registrarName = `${factoryContext.label}.${factoryContext.TLD}`;
      const mintContext: MintContext = {
        expiry: BigInt(0),
        fee: BigInt(0),
        label: "testing1",
        owner: owner.account.address,
        parentNode: namehash(registrarName),
        paymentReceiver: owner.account.address,
        price: BigInt(0),
        nonce: randomNonce()
      };

      const fullSubname = `${mintContext.label}.${registrarName}`;
      const subnameNode = namehash(fullSubname);
      const mintSignature = await generateMintContextSignature(
        mintContext,
        verifier,
        chainId,
        controller.address
      );

      const resolverData: Hash[] = [];

      //set avatar
      resolverData.push(
        encodeFunctionData({
          abi: parseAbi([
            "function setText(bytes32 node, string key, string value) external",
          ]),
          args: [subnameNode, "avatar", "avatar-uri"],
          functionName: "setText",
        })
      );
      //set address
      resolverData.push(
        encodeFunctionData({
          abi: parseAbi([
            "function setAddr(bytes32 node, uint256 coinType, bytes newAddress) external",
          ]),
          args: [subnameNode, BigInt(60), owner.account.address],
          functionName: "setAddr",
        })
      );
      //set contenthash
      resolverData.push(
        encodeFunctionData({
          abi: parseAbi([
            "function setContenthash(bytes32 node, bytes contenthash) external",
          ]),
          args: [subnameNode, toHex("random-data")],
          functionName: "setContenthash",
        })
      );

      const tx = await controller.write.mint(
        [mintContext, mintSignature, resolverData, "0x"],
        {
          account: owner.account,
        }
      );
      await publicClient.waitForTransactionReceipt({ hash: tx });

      const avatarRecord = await resolver.read.text([subnameNode, "avatar"]);
      const addressRecord = await resolver.read.addr([subnameNode, BigInt(60)]);
      const contenthashRecord = await resolver.read.contenthash([subnameNode]);

      expect(avatarRecord).to.equal("avatar-uri", "Comparing avatar record");
      expect(addressRecord).to.equal(
        owner.account.address,
        "Comparing address record"
      );
      expect(contenthashRecord).to.equal(toHex("random-data"));
    });
  });

  describe("Factory", () => {
    it("Should properly deploy ENS name registry", async () => {
      const {
        controller,
        verifier,
        chainId,
        publicClient,
        nodeResolver,
        owner,
      } = await loadFixture(controllerFullFlowFixture);

      const tokenDeployment: FactoryContext = {
        expirableType: 0,
        label: "testlabel",
        owner: owner.account.address,
        parentControl: 0,
        TLD: "com",
        tokenName: "Token",
        tokenSymbol: "TKN",
      };

      const signature = await generateFactoryContextSignature(
        tokenDeployment,
        verifier,
        chainId,
        controller.address
      );

      const tx = await controller.write.deploy([tokenDeployment, signature]);
      await publicClient.waitForTransactionReceipt({ hash: tx });

      const events = await controller.getEvents.RegistryDeployed();

      const RegistryDeployedEvent = events[0];

      const registrarEnsName = `${tokenDeployment.label}.${tokenDeployment.TLD}`;
      const registrarNode = namehash(registrarEnsName);
      expect(RegistryDeployedEvent.args.TLD).to.equal(tokenDeployment.TLD);
      expect(RegistryDeployedEvent.args.label).to.equal(tokenDeployment.label);
      expect(RegistryDeployedEvent.args.node).to.equal(registrarNode);
      expect(RegistryDeployedEvent.args.owner?.toLocaleLowerCase()).to.equal(
        tokenDeployment.owner.toLocaleLowerCase()
      );
      expect(RegistryDeployedEvent.args.tokenName).to.equal(
        tokenDeployment.tokenName
      );
      expect(RegistryDeployedEvent.args.tokenSymbol).to.equal(
        tokenDeployment.tokenSymbol
      );

      const expectedRegistrarAddress = await nodeResolver.read.nodeRegistries([
        registrarNode,
      ]);

      expect(expectedRegistrarAddress.toLocaleLowerCase()).to.equal(
        RegistryDeployedEvent.args.registryAddress?.toLocaleLowerCase(),
        "Expected the registry address matches the address from nodeResolver"
      );
    });
  });

  describe("Expiries", () => {
    it("Should be able to mint subname again after subname expires", async () => {
      const {
        controller,
        verifier,
        chainId,
        publicClient,
        owner,
        treasury,
        nodeResolver,
        resolver,
      } = await loadFixture(controllerFullFlowFixture);

      const tokenDeployment: FactoryContext = {
        expirableType: 1,
        label: "expirable",
        owner: owner.account.address,
        parentControl: 0,
        TLD: "xyz",
        tokenName: "Token",
        tokenSymbol: "TKN",
      };

      const registrarName = "expirable.xyz";
      const signature = await generateFactoryContextSignature(
        tokenDeployment,
        verifier,
        chainId,
        controller.address
      );

      const tx = await controller.write.deploy([tokenDeployment, signature]);
      await publicClient.waitForTransactionReceipt({ hash: tx });

      const mintContext: MintContext = {
        expiry: BigInt(ONE_YEAR_EXPIRY_SECONDS),
        fee: BigInt(0),
        price: BigInt(0),
        label: "testing",
        owner: owner.account.address,
        parentNode: namehash(registrarName),
        paymentReceiver: owner.account.address,
        nonce: randomNonce()
      };

      const subnameNode = namehash(`testing.expirable.xyz`);

      const mintSignature = await generateMintContextSignature(
        mintContext,
        verifier,
        chainId,
        controller.address
      );
      const tx01 = await controller.write.mint([
        mintContext,
        mintSignature,
        [],
        "0x",
      ]);
      await publicClient.waitForTransactionReceipt({ hash: tx01 });
      mintContext.nonce = randomNonce();
      const mintSignatureV2 = await generateMintContextSignature(
        mintContext,
        verifier,
        chainId,
        controller.address
      );
      await expect(
        controller.write.mint([mintContext, mintSignature, [], "0x"])
      ).to.be.rejected;
      await expect(
        controller.write.mint([mintContext, mintSignatureV2, [], "0x"])
      ).to.be.rejectedWith(
        `reverted with custom error 'NodeTaken("${subnameNode}", "testing")`
      );

      // wait for 2 years
      const nextBlockTimestamp =
        (await time.latest()) + ONE_YEAR_EXPIRY_SECONDS * 2;
      await time.setNextBlockTimestamp(nextBlockTimestamp);

      mintContext.owner = treasury.account.address;
      mintContext.expiry = BigInt(nextBlockTimestamp + ONE_YEAR_EXPIRY_SECONDS);
      const mintSignatureV3 = await generateMintContextSignature(
        mintContext,
        verifier,
        chainId,
        controller.address
      );

      const tx02 = await controller.write.mint([
        mintContext,
        mintSignatureV3,
        [],
        "0x",
      ]);

      await publicClient.waitForTransactionReceipt({ hash: tx02 });

      const registrarAddress = await nodeResolver.read.nodeRegistries([
        subnameNode,
      ]);
      const expirableRegistrar = await hre.viem.getContractAt(
        "EnsNameRegistry",
        registrarAddress
      );

      const newOwner = await expirableRegistrar.read.ownerOf([
        BigInt(subnameNode),
      ]);

      expect(newOwner.toLocaleLowerCase()).to.equal(
        treasury.account.address.toLocaleLowerCase()
      );
    });

    it("Should be able to extend expiry", async () => {
      const {
        controller,
        verifier,
        chainId,
        publicClient,
        owner,
        treasury,
        resolver,
        nodeResolver,
      } = await loadFixture(controllerFullFlowFixture);

      const tokenDeployment: FactoryContext = {
        expirableType: 1,
        label: "expirable",
        owner: owner.account.address,
        parentControl: 0,
        TLD: "xyz",
        tokenName: "Token",
        tokenSymbol: "TKN",
      };

      const registrarName = "expirable.xyz";
      const signature = await generateFactoryContextSignature(
        tokenDeployment,
        verifier,
        chainId,
        controller.address
      );

      const tx = await controller.write.deploy([tokenDeployment, signature]);
      await publicClient.waitForTransactionReceipt({ hash: tx });

      const registrarAddress = await nodeResolver.read.nodeRegistries([
        namehash(registrarName),
      ]);
      const registry = await hre.viem.getContractAt(
        "EnsNameRegistry",
        registrarAddress
      );

      const mintContext: MintContext = {
        expiry: BigInt(ONE_YEAR_EXPIRY_SECONDS),
        fee: BigInt(0),
        label: "testing",
        owner: owner.account.address,
        parentNode: namehash(registrarName),
        paymentReceiver: owner.account.address,
        price: BigInt(0),
        nonce: randomNonce()
      };

      const mintSignature = await generateMintContextSignature(
        mintContext,
        verifier,
        chainId,
        controller.address
      );

      const tx01 = await controller.write.mint([
        mintContext,
        mintSignature,
        [],
        "0x",
      ]);

      await publicClient.waitForTransactionReceipt({ hash: tx01 });

      const subname = `${mintContext.label}.${tokenDeployment.label}.${tokenDeployment.TLD}`;
      const node = namehash(subname);

      const expiry = await registry.read.expiries([node]);
      const expectedExpiry = (await time.latest()) + ONE_YEAR_EXPIRY_SECONDS;
      expect(expiry).to.equal(BigInt(expectedExpiry));

      const extendExpiryContext: ExtendExpiryContext = {
        expiry: BigInt(ONE_YEAR_EXPIRY_SECONDS),
        fee: BigInt(0),
        node: node,
        price: BigInt(0),
        paymentReceiver: owner.account.address,
        nonce: randomNonce()
      };

      const expirySignature = await generateExtendExpiryContextSignature(
        extendExpiryContext,
        verifier,
        chainId,
        controller.address
      );

      const tx03 = await controller.write.extendExpiry([
        extendExpiryContext,
        expirySignature,
      ]);

      await publicClient.waitForTransactionReceipt({ hash: tx03 });

      const extendedExpiryResult = await registry.read.expiries([node]);

      expect(parseInt(extendedExpiryResult.toString())).to.be.greaterThan(
        parseInt(expiry.toString())
      );
    });
  });

  describe("Signatures", () => {
    it("Should fail with invalid signature, if parameters are different than one signed", async () => {
      const { controller, verifier, chainId, owner, resolver } =
        await loadFixture(controllerFullFlowFixture);

      const mintContext: MintContext = {
        expiry: BigInt(0),
        fee: BigInt(0),
        label: "test",
        owner: owner.account.address,
        parentNode: NAME_NODE,
        paymentReceiver: owner.account.address,
        price: BigInt(10000000),
        nonce: randomNonce()
      };

      const mintSig = await generateMintContextSignature(
        mintContext,
        verifier,
        chainId,
        controller.address
      );

      const invalidContext01 = { ...mintContext, price: BigInt(0) };

      await expect(controller.write.mint([invalidContext01, mintSig, [], "0x"]))
        .to.be.rejected;

      const factoryContext: FactoryContext = {
        expirableType: 0,
        label: "test",
        owner: owner.account.address,
        parentControl: 0,
        TLD: "eth",
        tokenName: "Name",
        tokenSymbol: "Symbol",
      };

      const factorySig = await generateFactoryContextSignature(
        factoryContext,
        verifier,
        chainId,
        controller.address
      );
      const invalidContext02: FactoryContext = {
        ...factoryContext,
        label: "vitalik",
      };

      await expect(controller.write.deploy([invalidContext02, factorySig])).to
        .be.rejected;
    });
  });

  describe("Fees and prices", () => {
    it("Should properly distribute mint price/fee and remainder", async () => {
      const fee = BigInt(parseEther("0.1", "wei"));
      const price = BigInt(parseEther("2", "wei"));
      const totalValueSent = BigInt(parseEther("5", "wei"));

      const {
        controller,
        verifier,
        chainId,
        owner,
        resolver,
        treasury,
        publicClient,
      } = await loadFixture(controllerFullFlowFixture);

      const [, , , wallet04] = await hre.viem.getWalletClients();

      const mintContext: MintContext = {
        expiry: BigInt(0),
        fee: fee,
        label: "test",
        owner: owner.account.address,
        parentNode: NAME_NODE,
        paymentReceiver: owner.account.address,
        price: price,
        nonce: randomNonce()
      };
      const mintSig = await generateMintContextSignature(
        mintContext,
        verifier,
        chainId,
        controller.address
      );

      const treasuryBalanceBefore = await publicClient.getBalance({
        address: treasury.account.address,
      });
      const ownerBalanceBefore = await publicClient.getBalance({
        address: owner.account.address,
      });
      const minterBalanceBefore = await publicClient.getBalance({
        address: wallet04.account.address,
      });

      const tx = await controller.write.mint([mintContext, mintSig, [], "0x"], {
        account: wallet04.account,
        value: totalValueSent,
      });

      const receipt = await publicClient.waitForTransactionReceipt({
        hash: tx,
      });

      const gasSpent = receipt.gasUsed * receipt.effectiveGasPrice;
      const treasuryBalanceAfter = await publicClient.getBalance({
        address: treasury.account.address,
      });
      const ownerBalanceAfter = await publicClient.getBalance({
        address: owner.account.address,
      });
      const minterBalanceAfter = await publicClient.getBalance({
        address: wallet04.account.address,
      });

      expect(treasuryBalanceAfter).to.equal(
        treasuryBalanceBefore + fee,
        "Treasury fees not sent properly"
      );
      expect(ownerBalanceAfter).to.equal(
        ownerBalanceBefore + price,
        "Owner fees not sent properly"
      );
      expect(minterBalanceAfter).to.equal(
        minterBalanceBefore - (fee + price + gasSpent),
        "Minter fees not sent properly"
      );
    });
  });
});
