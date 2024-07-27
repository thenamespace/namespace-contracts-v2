import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { controllerFullFlowFixture } from "./Fixtures";
import { generateMintContextSignature, MintContext, randomNonce } from "./SignaturesHelper";
import { namehash, toHex } from "viem";
import { expect } from "chai";

describe("NamePublicResolver", () => {
  it("Should be able to set records by owner", async () => {
    const { resolver, controller, owner, factoryContext, chainId, verifier, publicClient, treasury } =
      await loadFixture(controllerFullFlowFixture);

    const name = `${factoryContext.label}.${factoryContext.TLD}`;
    const parentNode = namehash(name);

    const mintContext: MintContext = {
      expiry: BigInt(0),
      fee: BigInt(0),
      label: "testing1",
      owner: owner.account.address,
      parentNode: parentNode,
      paymentReceiver: owner.account.address,
      price: BigInt(0),
      nonce: randomNonce()
    };

    const signature = await generateMintContextSignature(
      mintContext,
      verifier,
      chainId,
      controller.address
    );

    const tx = await controller.write.mint([mintContext, signature, [], "0x"]);

    await publicClient.waitForTransactionReceipt({hash:tx});

    const subname = `${mintContext.label}.${name}`
    const subnameNode = namehash(subname);

    await resolver.write.setText([subnameNode, "avatar", "avatar-text"]);
    await resolver.write.setAddr([subnameNode, BigInt(111), owner.account.address]);
    const tx03 = await resolver.write.setContenthash([subnameNode, toHex("some-data")]);

    await publicClient.waitForTransactionReceipt({hash: tx03});

    const currentText = await resolver.read.text([subnameNode, "avatar"]);
    expect(currentText).to.equal("avatar-text");
    const currentAddr = await resolver.read.addr([subnameNode, BigInt(111)]) as string;
    expect(currentAddr.toLocaleLowerCase()).to.equal(owner.account.address.toLocaleLowerCase())
    const currentContent = await resolver.read.contenthash([subnameNode])
    expect(currentContent.toLocaleLowerCase()).to.equal(toHex("some-data"))

    await expect(resolver.write.setText([subnameNode, "avatar", "invalid-owner"], {
        account: treasury.account
    })).to.be.rejected;

  });
});
