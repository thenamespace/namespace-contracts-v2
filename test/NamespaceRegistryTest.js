const { expect, assert } = require("chai");

describe("NamespaceRegistry", () => {    
    before(async () => {
        [owner, addr2] = await ethers.getSigners();
        namespaceRegistry = await ethers.getContractFactory("NamespaceRegistry");
        namespaceRegistry = await namespaceRegistry.deploy();
        
        await namespaceRegistry.connect(owner).setController(owner.address, true);
    });

    it("Should register listing", async () => {
        await namespaceRegistry.connect(owner).set("0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000", ["testLabel", "0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000", owner.address, true]);
        expect(await namespaceRegistry.get("0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000")).to.deep.equal(["testLabel", "0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000", owner.address, true]);
    });

    it("Should remove listing", async () => {
        await namespaceRegistry.connect(owner).set("0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000", ["testLabel", "0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000", owner.address, true]);
        
        const listing1 = await namespaceRegistry.get("0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000");
        
        await namespaceRegistry.connect(owner).remove("0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000");
        const listing2 = await namespaceRegistry.get("0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000");
        expect(listing2).to.be.not.equal(listing1);
        expect(listing2).to.deep.equal(["", "0x0000000000000000000000000000000000000000000000000000000000000000", "0x0000000000000000000000000000000000000000", false]);
    });

    it("Should revert set function becase caller is not a controller", async () => {
        try {
            await namespaceRegistry.connect(addr2).set("0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000", ["testLabel", "0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000", owner.address, true]);
            assert.fail('Expected revert not received');
        } catch (error) {
            assert(error.message.includes('Controllable: Caller is not a controller'));
        }
    });

    it("Should revert remove function becase caller is not a controller", async () => {
        await namespaceRegistry.connect(owner).set("0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000", ["testLabel", "0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000", owner.address, true]);
        
        try {
            await namespaceRegistry.connect(addr2).remove("0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000");
            
            assert.fail('Expected revert not received');
        } catch (error) {
            assert(error.message.includes('Controllable: Caller is not a controller'));
        }
    });

});