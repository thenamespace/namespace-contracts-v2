const { expect } = require("chai");
const { ethers } = require("hardhat");
const path = require("path");

describe("NamespaceLister", () => {
    const ensName = process.env.ENS_NAME;
    const unmintedEnsName = process.env.UNMINTED_ENS_NAME;
    const contractsOwnerAddress = process.env.CONTRACTS_OWNER_ADDRESS;
    const nameWrapperProxyAddress = process.env.NAME_WRAPPER_PROXY_ADDRESS;
    const namespaceRegistryAddress = process.env.NAMESPACE_REGISTRY_ADDRESS;
    const nameWrappperAddress = process.env.NAME_WRAPPER_ADDRESS;

    before(async () => {
        const contractsOwner = await ethers.getImpersonatedSigner(contractsOwnerAddress);

        impersonatedSigner = await ethers.getImpersonatedSigner(process.env.OWNER_OF_THE_NAME);

        [owner, addr2] = await ethers.getSigners();
        
        namespaceLister = await ethers.getContractFactory("NamespaceLister");
        namespaceLister = await namespaceLister.deploy(nameWrapperProxyAddress, nameWrappperAddress, namespaceRegistryAddress);

        await namespaceLister.connect(owner).setController(impersonatedSigner.address, true);
        await owner.sendTransaction({ to: impersonatedSigner.address, value: ethers.parseEther("1") });

        const nameWrapperProxyArtifact = require(path.resolve(__dirname, "../artifacts/contracts/NameWrapperProxy.sol/NameWrapperProxy.json"));
        const nameWrapperProxyAbi = nameWrapperProxyArtifact.abi;
        const nameWrapperProxy = new ethers.Contract(nameWrapperProxyAddress, nameWrapperProxyAbi, contractsOwner);

        await nameWrapperProxy.connect(contractsOwner).setController(namespaceLister.target, true);

        const namespaceRegistryArtifact = require(path.resolve(__dirname, "../artifacts/contracts/NamespaceRegistry.sol/NamespaceRegistry.json"));
        const namespaceRegistryAbi = namespaceRegistryArtifact.abi;
        const namespaceRegistry = new ethers.Contract(namespaceRegistryAddress, namespaceRegistryAbi, contractsOwner);

        await namespaceRegistry.connect(contractsOwner).setController(namespaceLister.target, true);
    });

    it("Should list", async () => {
        await new Promise((resolve, reject) => {
            namespaceLister.on("NameListed", (ensNameLabel, nameNode, operator, event) => {
                try {
                    expect(ensNameLabel).to.be.equal(ensName);
                    expect(operator).to.be.equal(impersonatedSigner.address);
                    resolve();
                } catch (error) {
                    reject(error);
                }
            });
    
            namespaceLister.connect(impersonatedSigner).list(ensName, impersonatedSigner.address).catch(reject);
        });
    });

    it("Should unlist", async () => {
        namespaceLister.connect(impersonatedSigner).list(ensName, impersonatedSigner.address);

        await new Promise((resolve, reject) => {
            namespaceLister.on("NameUnlisted", (ensNameLabel, nameNode, operator, event) => {
                try {
                    expect(ensNameLabel).to.be.equal(ensName);
                    expect(operator).to.be.equal(impersonatedSigner.address);
                    resolve();
                } catch (error) {
                    reject(error);
                }
            });
    
            namespaceLister.connect(impersonatedSigner).unlist(ensName).catch(reject);
        });    
    });

    it("Should revert listing because caller is not owner of the name", async () => {
        await expect(namespaceLister.connect(addr2).list(ensName, impersonatedSigner.address)).to.be.revertedWith("Not permitted");
    });

    it("Should revert listing because name is not minted", async () => {
        await expect(namespaceLister.connect(impersonatedSigner).list(unmintedEnsName, impersonatedSigner.address)).to.be.revertedWith("Not permitted");
    });


    it("Should revert unlisting because caller is not owner of the name", async () => {
        namespaceLister.connect(impersonatedSigner).list(ensName, impersonatedSigner.address);
        
        await expect(namespaceLister.connect(addr2).unlist(ensName)).to.be.revertedWith("Not permitted");
    });

    it("Should revert unlisting because name is not minted", async () => {
        await expect(namespaceLister.connect(impersonatedSigner).unlist(unmintedEnsName)).to.be.revertedWith("Not permitted");
    });

    it("Should revert unlisting because name is not listed", async () => {
        namespaceLister.connect(impersonatedSigner).unlist(ensName);
        await expect(namespaceLister.connect(impersonatedSigner).unlist(ensName)).to.be.reverted;
    });

});