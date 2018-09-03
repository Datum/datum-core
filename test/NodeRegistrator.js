const web3 = global.web3;
const NodeRegistrator = artifacts.require('NodeRegistrator');
const VaultManager = artifacts.require('VaultManager');
const ForeverStorage = artifacts.require('ForeverStorage');

contract('NodeRegistrator', function (accounts) {
    let registrator;
    let vault;
    let depositAmount = 1;
    let storageSize = 1024 * 1024 * 1024;
    let endpoint = 'http://test/api';
    let endpointDatum = 'http://node1.datum.org';
    let endpointDatumWrong = 'http://node1-datum.org';
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
        registrator = await NodeRegistrator.new();
        foreverStorage = await ForeverStorage.new();

        await foreverStorage.addAdmin(registrator.address);
        await registrator.setStorage(foreverStorage.address);
    });


    it("register storage node providing deposit", async function () {
        let region = Regions.EUROPE;
        let bandwidth = Bandwidths.MEDIUM;

        let result = await registrator.registerNode(endpoint, bandwidth, region, { from: accounts[0], value: web3.toWei(depositAmount, 'ether') });
        let nodeStruct = await registrator.getNodeInfo.call(accounts[0]);
       
        assert.equal(result.logs[1].event, "NodeRegistered", "Expected NodeRegistered event")
        assert.equal(nodeStruct[0], endpoint);
        assert.equal(nodeStruct[1], bandwidth);
        assert.equal(nodeStruct[2], region);
        assert.equal(nodeStruct[3], "active");
    });


    it("Re-register storage node providing no deposit", async function () {
        //change bandwith now and re-register without providing deposit
        let region = Regions.EUROPE;
        let bandwidth = Bandwidths.HIGH;

        result = await registrator.registerNode(endpoint, bandwidth, region, { from: accounts[0] });
        nodeStruct = await registrator.getNodeInfo.call(accounts[0]);


        assert.equal(result.logs[0].event, "NodeUpdated", "Expected StorageNodeRegistered event")
        assert.equal(nodeStruct[1], bandwidth);
    });

    it("check count", async function () {
        let region = Regions.EUROPE;
        let bandwidth = Bandwidths.MEDIUM;

        await registrator.registerNode(endpoint, bandwidth, region, { from: accounts[0], value: web3.toWei(depositAmount, 'ether') });
        let nodeCount = await registrator.getNodeCount();
       
        assert.equal(nodeCount.toNumber(), 1, "node count should be 1")
    });

    it("start unregister", async function () {
        await registrator.unregisterNodeStart({ from: accounts[0] });
        let nodeStatus = await registrator.getNodeStatus(accounts[0]);
        assert.equal(nodeStatus, "unregister", "node should be in unregister status");
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
});