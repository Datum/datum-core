const web3 = global.web3;
const NodeRegistrator = artifacts.require('NodeRegistrator');
const VaultManager = artifacts.require('VaultManager');

contract('NodeRegistrator', function (accounts) {
    let registrator;
    let vault;
    let depositAmount = 10;
    let endpoint = 'http://test/api';
    let Regions = {
        AMERICA : 0,
        EUROPE : 1,
        ASIA : 2,
        AUSTRALIA : 3,
        AFRICA : 4
    }
    let Bandwidths = {
        LOW : 0,
        MEDIUM : 1,
        HIGH : 2
    }

     //create new smart contract instance before each test method
    beforeEach(async function () {
        registrator = await NodeRegistrator.new();
    });


    it("set vault manager from owner", async function () {
        //create new vault
        let newVault = await VaultManager.new();

        //set vault
        let result = await registrator.setVaultManager(newVault.address, { from: accounts[0] });

        //read vault from contract
        let contractVault = await registrator.vault.call();

        //check if new adddres correctly set
        assert.equal(contractVault, newVault.address, "Expected vault set to new vault")
    });

    it("set vault manager from other address (should fail)", async function () {

        let addError;

        try {
            //create new vault
            vault = await VaultManager.new();
            let result = await registrator.setVaultManager(vault.address, { from: accounts[1] });
        } catch (error) {
            addError = error;
        }

        //read vault from contract
        let newAddress = await registrator.vault.call();
      
        assert.notEqual(addError, undefined, 'Error must be thrown');
        assert.notEqual(newAddress, vault.address, "Expected vault set to new vault")
    });


    it("register storage node providing deposit", async function () {
        let region = Regions.EUROPE;
        let bandwidth = Bandwidths.MEDIUM;

        let result = await registrator.registerNode(endpoint, bandwidth, region, { from: accounts[0], value: web3.toWei(depositAmount, 'ether') });
        let nodeStruct = await registrator.registeredNodes.call(accounts[0]);
       
        assert.equal(result.logs[0].event, "NodeRegistered", "Expected NodeRegistered event")
        assert.equal(nodeStruct[0], endpoint);
        assert.equal(nodeStruct[1], bandwidth);
        assert.equal(nodeStruct[2], region);
        
    });


    it("register storage node providing NO deposit", async function () {
        let addError;

        try {
            //create new vault
            let region = Regions.EUROPE;
            let bandwidth = Bandwidths.MEDIUM;
            let result = await registrator.registerNode(endpoint, bandwidth, region, { from: accounts[0] });
        } catch (error) {
            addError = error;
        }

        assert.notEqual(addError, undefined, 'Error must be thrown');
    });

    it("Re-register storage node providing no deposit", async function () {
        let region = Regions.EUROPE;
        let bandwidth = Bandwidths.MEDIUM;

        let result = await registrator.registerNode(endpoint, bandwidth, region, { from: accounts[0], value: web3.toWei(depositAmount, 'ether') });
        let nodeStruct = await registrator.registeredNodes.call(accounts[0]);

        
        assert.equal(result.logs[0].event, "NodeRegistered", "Expected StorageNodeRegistered event")
        assert.equal(nodeStruct[0], endpoint);
        assert.equal(nodeStruct[1], bandwidth);
        assert.equal(nodeStruct[2], region);


        //change bandwith now and re-register without providing deposit
        bandwidth = Bandwidths.HIGH;

        result = await registrator.registerNode(endpoint, bandwidth, region, { from: accounts[0] });
        nodeStruct = await registrator.registeredNodes.call(accounts[0]);

        
        assert.equal(result.logs[0].event, "NodeRegistered", "Expected StorageNodeRegistered event")
        assert.equal(nodeStruct[1], bandwidth);
    });
});