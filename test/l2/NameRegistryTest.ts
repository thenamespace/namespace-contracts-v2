import { loadFixture, time } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import hre from "hardhat";
import { Address, Hash, namehash, zeroAddress } from "viem";

const ENS_NAME = "namespace.eth";
const NAME_NODE = namehash(ENS_NAME);
const NAME_REGISTRAR_OWNER = "0x6CaBE5E77F90d58600A3C13127Acf6320Bee0aA7";
const METADATA_URI = "https://dummy-metadata-uri";
const TOKEN_NAME = "namespace";
const TOKEN_SYMBOL = "NS";
const RESOLVER_ADDRESS = "0x6CaBE5E77F90d58600A3C13127Acf6320Bee0aA7";
const ONE_YEAR_EXPIRY_SECONDS = 365 * 24 * 60 * 60;

enum ParentControlType {
  NonControllable = 0,
  Controllable = 1,
}

enum ExpirableType {
  NonExpirable = 0,
  Expirable = 1,
}

interface RegistrarConfig {
  parentControlType: ParentControlType;
  expirableType: ExpirableType;
  tokenName: string;
  tokenSymbol: string;
  metadataUri: string;
  tokenOwner: string;
  tokenResolver: string;
  namehash: Hash;
  emitter: Address
}

const config: RegistrarConfig = {
  expirableType: ExpirableType.Expirable,
  metadataUri: METADATA_URI,
  parentControlType: ParentControlType.Controllable,
  namehash: NAME_NODE,
  tokenName: TOKEN_NAME,
  tokenOwner: NAME_REGISTRAR_OWNER,
  tokenResolver: RESOLVER_ADDRESS,
  tokenSymbol: TOKEN_SYMBOL,
  emitter: zeroAddress
};

describe("EnsNameRegistry", () => {
  async function deployRegistrarExpirableAndControllable() {
    // Contracts are deployed using the first signer/account by default
    const [wallet01, wallet02, wallet03] = await hre.viem.getWalletClients();
    const emitter = await hre.viem.deployContract("RegistryEmitter");
    const tx0 = await emitter.write.setController([wallet01.account.address, true]);
    const pc = await hre.viem.getPublicClient()

    await pc.waitForTransactionReceipt({ hash: tx0 });

    const cfg = { ...config, tokenOwner: wallet01.account.address, emitter: emitter.address };

    const registry = await hre.viem.deployContract("EnsNameRegistry", [cfg]);

    const tx1 = await registry.write.setController([
      wallet02.account.address,
      true,
    ]);
    await pc.waitForTransactionReceipt({ hash: tx1 });



    const tx2 = await emitter.write.setApprovedEmitter([registry.address, true])

    await pc.waitForTransactionReceipt({ hash: tx2 });

    return {
      registry,
      tokenOwner: wallet01,
      tokenDelegate: wallet02,
      publicClient: pc,
      emitter
    };
  }

  async function deployRegistrarNonExpirableAndNonControllable() {
    const [wallet01, wallet02, wallet03] = await hre.viem.getWalletClients();
    const emitter = await hre.viem.deployContract("RegistryEmitter");

    const pc = await hre.viem.getPublicClient();

    const tx0 = await emitter.write.setController([wallet01.account.address, true]);

    await pc.waitForTransactionReceipt({ hash: tx0 });

    const cfg: RegistrarConfig = {
      ...config,
      tokenOwner: wallet01.account.address,
      parentControlType: ParentControlType.NonControllable,
      expirableType: ExpirableType.NonExpirable,
      emitter: emitter.address
    };

    const registry = await hre.viem.deployContract("EnsNameRegistry", [cfg]);

    const tx01 = await registry.write.setController([
      wallet02.account.address,
      true,
    ]);
    await pc.waitForTransactionReceipt({ hash: tx01 });

    const tx2 = await emitter.write.setApprovedEmitter([registry.address, true])

    await pc.waitForTransactionReceipt({ hash: tx2 });

    return {
      registry,
      tokenOwner: wallet01,
      tokenDelegate: wallet02,
      publicClient: pc,
    };
  }
  describe("Deploy registry and Verify Configuration", () => { 
    it("Should properly configure ENS registry", async () => {
      const { registry, tokenOwner } = await loadFixture(
        deployRegistrarExpirableAndControllable
      );

      const nameTokenId = BigInt(NAME_NODE);
      const tokenName = await registry.read.name();
      const tokenSymbol = await registry.read.symbol();
      const tokenUri = await registry.read.tokenURI([nameTokenId]);
      const registrarNodeOwner = await registry.read.ownerOf([nameTokenId]);

      expect(tokenName).to.equal(TOKEN_NAME);
      expect(tokenSymbol).to.equal(TOKEN_SYMBOL);
      expect(tokenUri).to.equal(`${METADATA_URI}${nameTokenId.toString()}`);
      expect(tokenName).to.equal(TOKEN_NAME);
      expect(registrarNodeOwner.toLocaleLowerCase()).to.equal(
        tokenOwner.account.address.toLocaleLowerCase()
      );
    });
  });

  describe("EnsRegistrar with expiry and controllable", () => {
    it("Should be able to mint subname, mint again after expiry", async () => {
      const subnameLabel = "test-label";

      const [,,wallet] = await hre.viem.getWalletClients();

      const { registry, tokenOwner, tokenDelegate, publicClient } =
        await loadFixture(deployRegistrarExpirableAndControllable);
      // Register a subname by registry delegate
      const tx = await registry.write.register(
        [
          subnameLabel,
          tokenOwner.account.address,
          BigInt(ONE_YEAR_EXPIRY_SECONDS),
        ],
        {
          account: tokenDelegate.account,
        }
      );

      await publicClient.waitForTransactionReceipt({ hash: tx });

      const fullName = `${subnameLabel}.${ENS_NAME}`;
      const node = namehash(fullName);

      const nodeOwner = await registry.read.ownerOf([BigInt(node)]);

      expect(nodeOwner.toLocaleLowerCase()).to.equal(
        tokenOwner.account.address.toLocaleLowerCase()
      );

      // Mint should fail if minter is not a registry controller/token owner
      await expect(
        registry.write.register(
          [
            subnameLabel + "123",
            tokenOwner.account.address,
            BigInt(ONE_YEAR_EXPIRY_SECONDS),
          ],
          {
            account: wallet.account,
          }
        )
      ).to.rejectedWith("Controllable: Caller is not a controller");

      // Mint should fail if we attempt to register already registered subname
      await expect(
        registry.write.register(
          [
            subnameLabel,
            tokenOwner.account.address,
            BigInt(ONE_YEAR_EXPIRY_SECONDS),
          ],
          {
            account: tokenDelegate.account,
          }
        )
      ).to.rejectedWith(
        `reverted with custom error 'NodeTaken("${node}", "${subnameLabel}")'`
      );

      const blockTimestamp = (await publicClient.getBlock()).timestamp;

      // Should be able to mint if subname has expired
      await time.setNextBlockTimestamp(
        blockTimestamp + BigInt(ONE_YEAR_EXPIRY_SECONDS + 1000)
      );

      const tx1 = await registry.write.register(
        [
          subnameLabel,
          tokenDelegate.account.address,
          BigInt(ONE_YEAR_EXPIRY_SECONDS + ONE_YEAR_EXPIRY_SECONDS),
        ],
        {
          account: tokenDelegate.account,
        }
      );
      await publicClient.waitForTransactionReceipt({ hash: tx1 });

      const newOwner = await registry.read.ownerOf([BigInt(node)]);

      expect(newOwner.toLocaleLowerCase()).to.equal(
        tokenDelegate.account.address.toLocaleLowerCase()
      );
    });

    it("Should be able to burn minted subname by controller", async () => {
      const subnameLabel = "test-label";
      const oneYearExpiry = (await time.latest()) + ONE_YEAR_EXPIRY_SECONDS;

      const { registry, tokenOwner, tokenDelegate, publicClient } =
        await loadFixture(deployRegistrarExpirableAndControllable);

      const tx01 = await registry.write.setController([tokenOwner.account.address, true]);
      await publicClient.waitForTransactionReceipt({hash: tx01});

      // Register a subname by registry delegate
      const tx = await registry.write.register(
        [
          subnameLabel,
          tokenOwner.account.address,
          BigInt(oneYearExpiry),
        ],
        {
          account: tokenDelegate.account,
        }
      );

      await publicClient.waitForTransactionReceipt({ hash: tx });

      const fullName = `${subnameLabel}.${ENS_NAME}`;
      const node = namehash(fullName);

      const owner = await registry.read.ownerOf([BigInt(node)]);

      expect(owner.toLocaleLowerCase()).to.equal(
        tokenOwner.account.address.toLocaleLowerCase()
      );

      const tx1 = await registry.write.burn([node]);
      await publicClient.waitForTransactionReceipt({ hash: tx1 });

      const owner01 = await registry.read.ownerOf([BigInt(node)]);

      expect(owner01.toLocaleLowerCase()).to.equal(zeroAddress);
    });

    it("Should return zeroAddress owner for expired name", async () => {
      const subnameLabel = "test-label";

      const { registry, tokenOwner, tokenDelegate, publicClient } =
        await loadFixture(deployRegistrarExpirableAndControllable);

      // Register a subname by registry delegate
      const tx = await registry.write.register(
        [
          subnameLabel,
          tokenOwner.account.address,
          BigInt(ONE_YEAR_EXPIRY_SECONDS),
        ],
        {
          account: tokenDelegate.account,
        }
      );

      await publicClient.waitForTransactionReceipt({ hash: tx });

      const fullName = `${subnameLabel}.${ENS_NAME}`;
      const node = namehash(fullName);

      const owner = await registry.read.ownerOf([BigInt(node)]);

      expect(owner.toLocaleLowerCase()).to.equal(
        tokenOwner.account.address.toLocaleLowerCase()
      );

      const futureBlockTimestamp =
        (await time.latest()) + ONE_YEAR_EXPIRY_SECONDS * 2;
      await time.increaseTo(futureBlockTimestamp);

      const expiredOwner = await registry.read.ownerOf([BigInt(node)]);
      expect(expiredOwner).to.be.equal(zeroAddress);
    });
  });

  describe("EnsRegistrar with non-expiry and un-controllable", () => {
    it("Should be able to mint subname with 0 expiry", async () => {
      const { registry, tokenOwner, tokenDelegate, publicClient } =
        await loadFixture(deployRegistrarNonExpirableAndNonControllable);

      const subnameLabel = "label";
      const fullName = `${subnameLabel}.${ENS_NAME}`;
      const node = namehash(fullName);

      const tx = await registry.write.register(
        [subnameLabel, tokenOwner.account.address, BigInt(0)],
        {
          account: tokenDelegate.account,
        }
      );

      await publicClient.waitForTransactionReceipt({ hash: tx });

      const owner = await registry.read.ownerOf([BigInt(node)]);

      expect(owner.toLocaleLowerCase()).to.equal(
        tokenOwner.account.address.toLocaleLowerCase()
      );
    });

    it("registry owner should not be able to burn subnames", async () => {
      const { registry, tokenOwner, publicClient } =
        await loadFixture(deployRegistrarNonExpirableAndNonControllable);

      const subnameLabel = "label";
      const fullName = `${subnameLabel}.${ENS_NAME}`;
      const node = namehash(fullName);

      const tx01 = await registry.write.setController([tokenOwner.account.address, true]);
      await publicClient.waitForTransactionReceipt({ hash: tx01 });

      const tx = await registry.write.register(
        [subnameLabel, tokenOwner.account.address, BigInt(0)],
        {
          account: tokenOwner.account,
        }
      );

      await publicClient.waitForTransactionReceipt({ hash: tx });

      const owner = await registry.read.ownerOf([BigInt(node)]);

      expect(owner.toLocaleLowerCase()).to.equal(
        tokenOwner.account.address.toLocaleLowerCase()
      );

      await expect(registry.write.burn([node])).to.be.rejectedWith(
        `reverted with custom error 'NodeNotControllable()'`
      );
    });

    it("Should be able to mint name with multiple levels", async () => {
      const { registry, tokenOwner, tokenDelegate, publicClient } =
        await loadFixture(deployRegistrarNonExpirableAndNonControllable);

      const tx = await registry.write.register(
        [
          ["test3", "test2", "test1"],
          tokenOwner.account.address,
          BigInt(0),
        ],
        {
          account: tokenDelegate.account,
        }
      );

      await publicClient.waitForTransactionReceipt({ hash: tx });

      const fullName = "test1.test2.test3." + ENS_NAME;
      const nameNode = namehash(fullName);

      const currentOwner = await registry.read.ownerOf([BigInt(nameNode)]);

      expect(currentOwner.toLocaleLowerCase()).to.equal(
        tokenOwner.account.address.toLocaleLowerCase()
      );
    });
  });

  describe("Owner should be able to set contollers and transfer ownership", () => {
    
    it("Owner should be able to set controllers", async () => {
      const { registry, tokenOwner, tokenDelegate, publicClient } =
        await loadFixture(deployRegistrarNonExpirableAndNonControllable);

      const isTokenDelegate = await registry.read.controllers([
        tokenDelegate.account.address,
      ]);
      expect(isTokenDelegate).to.be.true;

      await expect(
        registry.write.setController(
          [tokenOwner.account.address, true],
          {
            account: tokenDelegate.account,
          }
        )
      ).to.be.rejected;
    });
  });
});
