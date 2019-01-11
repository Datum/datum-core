const web3 = global.web3;
const NodeRegistrator = artifacts.require('NodeRegistrator');
const NodeRegistratorData = artifacts.require('NodeRegistratorData');
const VaultManager = artifacts.require('VaultManager');
const ForeverStorage = artifacts.require('ForeverStorage');
const StorageKeys = artifacts.require('StorageKeys');


contract('NodeRegistrator', function (accounts) {
    let registrator;
    let registratorData;
    let vault;
    let storageKeys;
    let depositAmount = 1;
    let storageSize = 1024 * 1024 * 1024;
    let endpoint = 'test.mydomain.com';
    let endpointDatum = 'node1.datum.org';
    let endpointDatumWihtPort = 'node1.datum.org:5555';
    let Regions = {
        AMERICA : 0,
        EUROPE : 1,
        ASIA : 2,
        AUSTRALIA : 3,
        AFRICA : 4,
        RUSSIA : 5,
        CHINA : 6
    }
    let Bandwidths = {
        LOW : 0,
        MEDIUM : 1,
        HIGH : 2
    }

     //create new smart contract instance before all tests
    before(async function () {
        storageKeys = await StorageKeys.new();
        foreverStorage = await ForeverStorage.new();
        vault = await VaultManager.new();

        registratorData = await NodeRegistratorData.new(foreverStorage.address, storageKeys.address);
        registrator = await NodeRegistrator.new(vault.address, foreverStorage.address, storageKeys.address, registratorData.address);
        
        await vault.addAdmin(registrator.address);
        await registratorData.addAdmin(registrator.address);
        await foreverStorage.addAdmin(registrator.address);
        await foreverStorage.addAdmin(registratorData.address);
        await registrator.setStorage(foreverStorage.address);
    });


    it("register storage node providing deposit as non-datum node", async function () {
        let region = Regions.EUROPE;
        let bandwidth = Bandwidths.MEDIUM;

        let result = await registrator.registerNode(endpoint, bandwidth, region, { from: accounts[0], value: web3.toWei(depositAmount, 'ether') });
        let nodeStruct = await registrator.getNodeInfo.call(accounts[0]);
     
        assert.equal(result.logs[1].event, "NodeRegistered", "Expected NodeRegistered event")
        assert.equal(nodeStruct[0], endpoint);
        assert.equal(nodeStruct[1], bandwidth);
        assert.equal(nodeStruct[2], region);
        assert.equal(nodeStruct[3], "active");
        assert.equal(nodeStruct[5], false);
    });


    it("check max storage amount for node", async function () {
        let region = Regions.EUROPE;
        let bandwidth = Bandwidths.MEDIUM;

        let maxAmount = await registrator.getMaxStorageAmount(accounts[0], { from: accounts[0] });

        console.log(maxAmount);
        console.log(maxAmount.toNumber());
    });


    /*

    it("register storage node providing deposit as Datum node", async function () {
        let region = Regions.EUROPE;
        let bandwidth = Bandwidths.MEDIUM;

        let result = await registrator.registerNode(endpointDatum, bandwidth, region, { from: accounts[1], value: web3.toWei(depositAmount, 'ether') });
        let nodeStruct = await registrator.getNodeInfo.call(accounts[1]);
     
        assert.equal(result.logs[1].event, "NodeRegistered", "Expected NodeRegistered event")
        assert.equal(nodeStruct[0], endpointDatum);
        assert.equal(nodeStruct[1], bandwidth);
        assert.equal(nodeStruct[2], region);
        assert.equal(nodeStruct[3], "active");
        assert.equal(nodeStruct[5], true);
    });

    it("register storage node providing deposit as Datum node with port in url", async function () {
        let region = Regions.EUROPE;
        let bandwidth = Bandwidths.MEDIUM;

        let result = await registrator.registerNode(endpointDatumWihtPort, bandwidth, region, { from: accounts[2], value: web3.toWei(depositAmount, 'ether') });
        let nodeStruct = await registrator.getNodeInfo.call(accounts[2]);
     
        assert.equal(result.logs[1].event, "NodeRegistered", "Expected NodeRegistered event")
        assert.equal(nodeStruct[0], endpointDatumWihtPort);
        assert.equal(nodeStruct[1], bandwidth);
        assert.equal(nodeStruct[2], region);
        assert.equal(nodeStruct[3], "active");
        assert.equal(nodeStruct[5], true);
    });


    it("Re-register storage node providing no deposit with new bandwith", async function () {
        //change bandwith now and re-register without providing deposit
        let region = Regions.EUROPE;
        let bandwidth = Bandwidths.HIGH;

        result = await registrator.registerNode(endpoint, bandwidth, region, { from: accounts[0] });
        nodeStruct = await registrator.getNodeInfo.call(accounts[0]);
        assert.equal(result.logs[0].event, "NodeUpdated", "Expected StorageNodeRegistered event")
        assert.equal(nodeStruct[1], bandwidth);
    });


    it("Re-register storage node with datum URL to check if changed", async function () {
        //change bandwith now and re-register without providing deposit
        let region = Regions.EUROPE;
        let bandwidth = Bandwidths.HIGH;

        result = await registrator.registerNode(endpointDatumWihtPort, bandwidth, region, { from: accounts[0] });
        nodeStruct = await registrator.getNodeInfo.call(accounts[0]);

        assert.equal(result.logs[0].event, "NodeUpdated", "Expected NodeRegistered event")
        assert.equal(nodeStruct[0], endpointDatumWihtPort);
        assert.equal(nodeStruct[1], bandwidth);
        assert.equal(nodeStruct[2], region);
        assert.equal(nodeStruct[3], "active");
        assert.equal(nodeStruct[5], true);
    });

    it("check count", async function () {
        let region = Regions.EUROPE;
        let bandwidth = Bandwidths.MEDIUM;

        await registrator.registerNode(endpoint, bandwidth, region, { from: accounts[0], value: web3.toWei(depositAmount, 'ether') });
        let nodeCount = await registrator.getNodeCount();
       
        assert.equal(nodeCount.toNumber(), 3, "node count should be 3")
    });

    it("start unregister", async function () {
        await registrator.unregisterNodeStart({ from: accounts[0] });
        let nodeStatus = await registrator.getNodeInfo(accounts[0]);
        assert.equal(nodeStatus[3], "unregister", "node should be in unregister status");
    });

    it("fullfill unregister (should fail)", async function () {
        let addError;

        try {
            await registrator.unregisterNode({ from: accounts[0] });
        } catch (error) {
            addError = error;
        }

        assert.notEqual(addError, undefined, 'Error must be thrown');
    });
    */
});