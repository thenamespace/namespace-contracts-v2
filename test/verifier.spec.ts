import { expect } from "chai";
import { BrowserProvider, FetchRequest } from "ethers";
import hre, { ethers } from "hardhat";
import { TestL1 } from "../typechain-types";

describe("OPVerifier", () => {
  let provider: BrowserProvider;
  let signer;
  let target: TestL1;

  before(async () => {
    const getUrl = FetchRequest.createGetUrlFunc();
    ethers.FetchRequest.registerGetUrl(async (req: FetchRequest) => {
      return getUrl(req);
    });

    provider = new ethers.BrowserProvider(hre.network.provider);
    signer = await provider.getSigner(0);

    target = await ethers.getContractAt(
      "TestL1",
      "0x29023DE63D7075B4cC2CE30B55f050f9c67548d4", // TestL1 localhost
      // "0xF9BAea670660CC86320c4BfD94486D3f1751648C", // TestL1 on Sepolia
      signer
    );
  });

  it("simple proofs for fixed values", async () => {
    const result = await target.getLatest({ enableCcipRead: true });
    expect(Number(result)).to.eq(42);
  });

  it("simple proofs for dynamic values", async () => {
    const result = await target.getName({ enableCcipRead: true });
    expect(result).to.eq("Satoshi");
  });

  it("nested proofs for dynamic values", async () => {
    const result = await target.getHighscorer(42, { enableCcipRead: true });
    expect(result).to.eq("Hal Finney");
  });

  it("nested proofs for long dynamic values", async () => {
    const result = await target.getHighscorer(1, { enableCcipRead: true });
    expect(result).to.eq(
      "Hubert Blaine Wolfeschlegelsteinhausenbergerdorff Sr."
    );
  });

  it("nested proofs with lookbehind", async () => {
    const result = await target.getLatestHighscore({ enableCcipRead: true });
    expect(Number(result)).to.eq(12345);
  });

  it("nested proofs with lookbehind for dynamic values", async () => {
    const result = await target.getLatestHighscorer({ enableCcipRead: true });
    expect(result).to.eq("Hal Finney");
  });

  it("mappings with variable-length keys", async () => {
    const result = await target.getNickname("Money Skeleton", {
      enableCcipRead: true,
    });
    expect(result).to.eq("Vitalik Buterin");
  });

  it("nested proofs of mappings with variable-length keys", async () => {
    const result = await target.getPrimaryNickname({ enableCcipRead: true });
    expect(result).to.eq("Hal Finney");
  });

  it("treats uninitialized storage elements as zeroes", async () => {
    const result = await target.getZero({ enableCcipRead: true });
    expect(Number(result)).to.eq(0);
  });

  it("treats uninitialized dynamic values as empty strings", async () => {
    const result = await target.getNickname("Santa", { enableCcipRead: true });
    expect(result).to.eq("");
  });
});
