const web3 = global.web3;
const StorageNodeContract = artifacts.require('StorageNodeContract');
const VaultManager = artifacts.require('VaultManager');
const StorageCostsContract = artifacts.require('StorageCostsContract');
const NodeRegistrator = artifacts.require('NodeRegistrator');
const StorageKeys = artifacts.require("StorageKeys");
const ForeverStorage = artifacts.require('ForeverStorage');
const StorageData = artifacts.require('StorageData');
const NodeData = artifacts.require('NodeRegistratorData');
const StorageProxyContract = artifacts.require('StorageProxyContract');

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

contract('StorageNodeContract', function (accounts) {
    let storage;
    let vault;
    let registrator;
    let costs;
    let storageProxy;


    //test params
    let hash = "0x18EE24150DCB1D96752A4D6DD0F20DFD8BA8C38527E40AA8509B7ADECF78F9C6";
    let hash2 = "0x28EE24150DCB1D96752A4D6DD0F20DFD8BA8C38527E40AA8509B7ADECF78F9C6";
    let hash3 = "0x38EE24150DCB1D96752A4D6DD0F20DFD8BA8C38527E40AA8509B7ADECF78F9C6";
    let hash4 = "0x48EE24150DCB1D96752A4D6DD0F20DFD8BA8C38527E40AA8509B7ADECF78F9C6";
    let hash5 = "0x58EE24150DCB1D96752A4D6DD0F20DFD8BA8C38527E40AA8509B7ADECF78F9C6";
    let hash6 = "0x68EE24150DCB1D96752A4D6DD0F20DFD8BA8C38527E40AA8509B7ADECF78F9C6";
    let hash7 = "0x78EE24150DCB1D96752A4D6DD0F20DFD8BA8C38527E40AA8509B7ADECF78F9C6";
    let hash8 = "0x88EE24150DCB1D96752A4D6DD0F20DFD8BA8C38527E40AA8509B7ADECF78F9C6";
    let hash9 = "0x98EE24150DCB1D96752A4D6DD0F20DFD8BA8C38527E40AA8509B7ADECF78F9C6";
    let hash10 = "0x08EE24150DCB1D96752A4D6DD0F20DFD8BA8C38527E40AA8509B7ADECF78F9C6";
    let root = "0x13C78C707B010724CD9E1F596B58246A2C829384FC8A8A4B49AA38B3FDDFC1C2";
    let secret = "0x5d521323580bc303b1dd9cf4f9dc3a90049a2a5aceb5e005233df99fac70d0edad1749cfee8744507992fa14ff682bc56a1955c3697f2b50ee409476cf6f75b8782bcc2fd2de3979d0f7e1285e990487599bf93686f165a5e47ec79e3089c821ac097e437caed37c43fa1a6625cab619a302da47ea50be6bba0124d3a893982f260fc8b0eb8d87ad8d88d25b76bc57f3e7";
    let secret2 = "0x7fe5b21c5edb868e1494f30813864653041ec18e051b1670b0437beee0ca1d890d32e2dcd7498ae298557a66325ae8a6be0347189915075577bc3059adff2c25cffcecccd984f44a8567fa158215d6df86031b1d9c235fd5a34383ff26a63dc81ea32cb52087df04fef83e0ee3e85cc7ddce9adfe3695ea16b2ee52a6bec2c78aae8ff1615ff59192bf8b2de07658ef3a2";
    let size = 1023334;
    let keyname = "TEST_KEY";
    let keyname2 = "0x7fe5b21c5edb868e1494f30813864653041ec18e051b1670b0437beee0ca1d890d32e2dcd7498ae298557a66325ae8a6be0347189915075577bc3059adff2c25cffcecccd984f44a8567fa158215d6df86031b1d9c235fd5a34383ff26a63dc81ea32cb52087df04fef83e0ee3e85cc7ddce9adfe3695ea16b2ee52a6bec2c78aae8ff1615ff59192bf8b2de07658ef3a20x7fe5b21c5edb868e1494f30813864653041ec18e051b1670b0437beee0ca1d890d32e2dcd7498ae298557a66325ae8a6be0347189915075577bc3059adff2c25cffcecccd984f44a8567fa158215d6df86031b1d9c235fd5a34383ff26a63dc81ea32cb52087df04fef83e0ee3e85cc7ddce9adfe3695ea16b2ee52a6bec2c78aae8ff1615ff59192bf8b2de07658ef3a20x7fe5b21c5edb868e1494f30813864653041ec18e051b1670b0437beee0ca1d890d32e2dcd7498ae298557a66325ae8a6be0347189915075577bc3059adff2c25cffcecccd984f44a8567fa158215d6df86031b1d9c235fd5a34383ff26a63dc81ea32cb52087df04fef83e0ee3e85cc7ddce9adfe3695ea16b2ee52a6bec2c78aae8ff1615ff59192bf8b2de07658ef3a20x7fe5b21c5edb868e1494f30813864653041ec18e051b1670b0437beee0ca1d890d32e2dcd7498ae298557a66325ae8a6be0347189915075577bc3059adff2c25cffcecccd984f44a8567fa158215d6df86031b1d9c235fd5a34383ff26a63dc81ea32cb52087df04fef83e0ee3e85cc7ddce9adfe3695ea16b2ee52a6bec2c78aae8ff1615ff59192bf8b2de07658ef3a20x7fe5b21c5edb868e1494f30813864653041ec18e051b1670b0437beee0ca1d890d32e2dcd7498ae298557a66325ae8a6be0347189915075577bc3059adff2c25cffcecccd984f44a8567fa158215d6df86031b1d9c235fd5a34383ff26a63dc81ea32cb52087df04fef83e0ee3e85cc7ddce9adfe3695ea16b2ee52a6bec2c78aae8ff1615ff59192bf8b2de07658ef3a20x7fe5b21c5edb868e1494f30813864653041ec18e051b1670b0437beee0ca1d890d32e2dcd7498ae298557a66325ae8a6be0347189915075577bc3059adff2c25cffcecccd984f44a8567fa158215d6df86031b1d9c235fd5a34383ff26a63dc81ea32cb52087df04fef83e0ee3e85cc7ddce9adfe3695ea16b2ee52a6bec2c78aae8ff1615ff59192bf8b2de07658ef3a2";
    let keys = [];
    let category = "email";
    let replicationMode = 1;
    let privacy = 1;
    let duration = 100;
    let price = 100;

    let Regions = {
        AMERICA: 0,
        EUROPE: 1,
        ASIA: 2,
        AUSTRALIA: 3,
        AFRICA: 4
    }
    let Bandwidths = {
        LOW: 0,
        MEDIUM: 1,
        HIGH: 2
    }



    //create new smart contract instance before all tests start
    before(async function () {
        
        vault = await VaultManager.new();
        vaultNode = await VaultManager.new();
        costs = await StorageCostsContract.new();
        storageKeys = await StorageKeys.new();
        foreverStorage = await ForeverStorage.new();

        


        storageData = await StorageData.new(foreverStorage.address, storageKeys.address);
        nodeData = await NodeData.new(foreverStorage.address, storageKeys.address);


        registrator = await NodeRegistrator.new(vaultNode.address, storageKeys.address, nodeData.address);
        storage = await StorageNodeContract.new(vault.address, registrator.address, foreverStorage.address, storageKeys.address, storageData.address );


        //add rights for storage
        await foreverStorage.addAdmin(storage.address);
        await foreverStorage.addAdmin(registrator.address);
        await foreverStorage.addAdmin(nodeData.address);
        await foreverStorage.addAdmin(storageData.address);

        await nodeData.addAdmin(registrator.address);
        await storageData.addAdmin(storage.address);



        
        await vault.addAdmin(storage.address);
        await vaultNode.addAdmin(registrator.address);

        //register 5 nodes
        await registrator.registerNode("http://test1.de", 0,0, { from: accounts[1], value: web3.toWei("1", 'ether') });
        await registrator.registerNode("http://test2.de", 0,0, { from: accounts[2], value: web3.toWei("1", 'ether') });
        await registrator.registerNode("http://test3.de", 0,0, { from: accounts[3], value: web3.toWei("1", 'ether') });
        await registrator.registerNode("devnode.datum.org", 0,0, { from: accounts[4], value: web3.toWei("1", 'ether') });
        //await registrator.registerNode("http://test4.de/api", 0,0, { from: accounts[4], value: web3.toWei("1", 'ether') });
        //await registrator.registerNode("http://test5.de/api", 0,0, { from: accounts[5], value: web3.toWei("1", 'ether') });

        storageProxy = await StorageProxyContract.new(storage.address);
        
    });

    it("check node registration", async function () {
        //get datum node, only one registrered from accounts[4]
        let dtNode = await registrator.getRandomDatumNode(1);
       
        assert.equal(dtNode, accounts[4], "Expected node with address: " + accounts[4]);
    });


    it("check max storage amounts for default node with 1 DAT deposit", async function () {
        let maxStorageAmount = await registrator.getMaxStorageAmount(accounts[1]);
       
        assert.equal(maxStorageAmount.toNumber(), 46084360, "Expected bytes size is 46084360");
    });

    it("check max storage amounts for datum node", async function () {
        let maxStorageAmount = await registrator.getMaxStorageAmount(accounts[4]);
       
        assert.isAtLeast(maxStorageAmount.toNumber(), 133352143234234, "Expected int max value for unlimited");
    });

    

    
    it("set storage deposit amount (from operator)", async function () {

        let newAmount = 111;

        let existingAmount = await storage.storageRegisterDepositAmount.call();
        
        let result = await storage.setStorageDepositAmount(newAmount, { from: accounts[0] });

        let newAmountStored = await storage.storageRegisterDepositAmount.call();
       
        assert.notEqual(existingAmount, newAmount, 'Vault must be changed');
        assert.equal(newAmount, newAmountStored, "Expected new vault set")
    });


    it("set storage deposit amount (from unknown account)", async function () {
        let addError;

        try {
            //contract throws error here
            let newAmount = 111;
            let result = await storage.setStorageDepositAmount(newAmount, { from: accounts[1] });
        } catch (error) {
            addError = error;
        }


        assert.notEqual(addError, undefined, 'Error must be thrown');
    });

    it("deposit to storage space", async function () {
        let depositAmountResult = await storage.deposit(accounts[0], { from: accounts[0], value: web3.toWei("1", 'ether') });
        assert.equal(depositAmountResult.logs[0].event, "Deposit", "Expected Deposit event")
    });

    
    it("deposit / withdrawal to storage space", async function () {
        let depositAmountResult = await storage.deposit(accounts[0],{ from: accounts[0], value: web3.toWei("1", 'ether') });
        let withdrawalAmountResult = await storage.withdrawal(accounts[0], web3.toWei("0.1",'ether'), { from: accounts[0] });

        assert.equal(withdrawalAmountResult.logs[0].event, "Withdrawal", "Expected Withdrawal event")
    });
    

    


    describe('storage tests', function () {

        beforeEach(async function () {
            /*
            await storage.deposit(accounts[0],{ from: accounts[0], value: web3.toWei("1", 'ether') });
            await storage.setCostsContract(costs.address, { from: accounts[0] });
            await registrator.registerMasterNode(accounts[0],"http://master1.de/api", 0,0,1000000, { from: accounts[0], value: web3.toWei("1", 'ether') });
            */
        });



        
        it("init storage node (providing deposit amount)", async function () {
            let nodeCount = await registrator.getNodeCount();
            assert.notEqual(nodeCount, 0 , "there should be nodes registered!");

            let addError;
            let result = await storage.setStorage(accounts[0], hash, root, keyname, size, replicationMode, [], { from: accounts[0] });

            let item = await storage.getItemForId(hash);
            let idsArray = await storage.getIdsForAccount(accounts[0]);
            let costsCalculated = await costs.getStorageCosts(size, duration);

            assert.equal(idsArray[idsArray.length - 1].toLowerCase(), hash.toLowerCase(), "Excecpted is in account list: " + idsArray[idsArray.length - 1].toLowerCase());

            assert.equal(item[0], accounts[0], "Excecpted owner is " + accounts[0]);
            assert.equal(item[1].toLowerCase(), root.toLowerCase(), "Excecpted merkle is " + root.toLowerCase());
            assert.equal(result.logs[0].event, "StorageItemAdded", "Expected StorageItemAdded event")
            assert.equal(result.logs[1].event, "StorageNodesSelected", "Expected StorageNodesSelected event")
            
        });


        
        it("init storage node with extra long key name", async function () {
            let nodeCount = await registrator.getNodeCount();
            assert.notEqual(nodeCount, 0 , "there should be nodes registered!");

            let addError;
            let result = await storage.setStorage(accounts[0], hash2, root, keyname2, size, replicationMode, [], { from: accounts[0] });

            let item = await storage.getItemForId(hash2);
            let idsArray = await storage.getIdsForAccount(accounts[0]);
            let costsCalculated = await costs.getStorageCosts(size, duration);

            assert.equal(idsArray[idsArray.length - 1].toLowerCase(), hash2.toLowerCase(), "Excecpted is in account list: " + idsArray[idsArray.length - 1].toLowerCase());

            assert.equal(item[0], accounts[0], "Excecpted owner is " + accounts[0]);
            assert.equal(item[1].toLowerCase(), root.toLowerCase(), "Excecpted merkle is " + root.toLowerCase());
            assert.equal(result.logs[0].event, "StorageItemAdded", "Expected StorageItemAdded event")
            assert.equal(result.logs[1].event, "StorageNodesSelected", "Expected StorageNodesSelected event")
            
        });


        
        it("check mappings by key", async function () {

            //add two more items under same key and 2 with different keys
            await storage.setStorage(accounts[0], hash4, root, keyname, size, replicationMode, [], { from: accounts[0] });
            await storage.setStorage(accounts[0], hash5, root, keyname, size, replicationMode, [], { from: accounts[0] });

            let idsArray = await storage.getIdsForKey(keyname);
            let lastIdForKey = await storage.getActualIdForKey(accounts[0], keyname);
            
            assert.equal(idsArray.length, 3, "There should be three item with this keyname");
            assert.equal(idsArray[2], lastIdForKey, "The last id for keyname should be same like 0 position");
        });


        it("check mappings by extra long key", async function () {
            await storage.setStorage(accounts[0], hash6, root, keyname2, size, replicationMode, [], { from: accounts[0] });
            await storage.setStorage(accounts[0], hash7, root, keyname2, size, replicationMode, [], { from: accounts[0] });

           
            let idsKey2Array = await storage.getIdsForKey(keyname2);
            let lastIdForKey2 = await storage.getActualIdForKey(accounts[0], keyname2);

            assert.equal(idsKey2Array.length, 3, "There should be three item with this keyname2");
            assert.equal(idsKey2Array[2], lastIdForKey2, "The last id for keyname should be same like 0 position");
        });

        


        it("init storage node (providing insufficient deposit amount)", async function () {
            let addError;

            //set big size
            let bigSize = 156465456651;

            try {
                //contract throws error here
                let result = await storage.setStorage(accounts[0], hash, root, keyname, size, replicationMode, [], { from: accounts[5] });
            } catch (error) {
                addError = error;
            }

            assert.notEqual(addError, undefined, 'Error must be thrown');
        });
        

        
        it("check node rewards", async function () {
            await sleep(3000);

            let node = await storage.getNodesForItem.call(hash);
            let rewards1 = await registrator.estimateRewards.call( { from: node[0] });
            let rewards2 = await registrator.estimateRewards.call( { from: node[1] });
            let rewards3 = await registrator.estimateRewards.call( { from: node[2] });

            let rewardsOther = await registrator.estimateRewards.call( { from: accounts[5] });

            assert.notEqual(rewards1.toNumber(), 0, "rewards for node 0 should be not 0");
            assert.notEqual(rewards2.toNumber(), 0, "rewards for node 1 should be not 0");
            assert.notEqual(rewards3.toNumber(), 0, "rewards for node 2 should be not 0");
            assert.equal(rewardsOther.toNumber(), 0, "rewards should be 0");


            let sizeStored = await registrator.getSizeStoredByNode(node[0]);
            console.log(sizeStored);

            let maxAmount = await registrator.getMaxStorageAmount(node[0]);
            console.log(maxAmount);
        });
        
        
        

        
        it("add access key to storage item", async function () {
            //add access
            let resultAccess = await storage.addAccess(hash, accounts[1],{ from: accounts[0] });

            let item = await storage.getItemForId(hash);
            let idsArray = await storage.getIdsForAccount(accounts[1]);
            let acl = await storage.getAccessKeysForData(hash);

            var msg = 123456789;

            let fixed_msg = `\x19Ethereum Signed Message:\n${32}${msg}`;
            let fixed_msg_sha = web3.sha3(fixed_msg);

            var signature = web3.eth.sign(accounts[0], web3.toHex(msg));

            signature = signature.substr(2); //remove 0x
            const r = '0x' + signature.slice(0, 64)
            const s = '0x' + signature.slice(64, 128)
            const v = '0x' + signature.slice(128, 130)
            const v_decimal = web3.toDecimal(v)
 
            //let canAccess = await storage.canKeyAccessData(hash,web3.toHex(msg), v_decimal, r, s);

            assert.equal(idsArray.length,  1, "There should be one id for this account");
            assert.equal(acl[1],  accounts[1], "Account 1 should be on access list");
            
        });


        it("remove access key to storage item", async function () {
            let addError;

            //add access
            let resultAccess = await storage.removeAccess(hash, accounts[1],{ from: accounts[0] });

            let item = await storage.getItemForId(hash);
            let idsArray = await storage.getIdsForAccount(accounts[1]);
            let acl = await storage.getAccessKeysForData(hash);

            assert.equal(idsArray.length,  0, "Account 1 list should be empty");
            assert.equal(acl.length,  1, "Access list should contain only 1 item");
            assert.equal(acl[0],  accounts[0], "Only Account 0 should have access");
        });


        
        it("force storage proof", async function () {
            let node = await storage.getNodesForItem.call(hash);
            let result = await storage.forceStorageProof(hash, node[0], { from: accounts[0] });

            assert.equal(result.logs[0].event, "StorageProofNeeded", "Expected StorageProofNeeded event")
        });
        

        

        it("transfer owner", async function () {
            let result = await storage.transferOwner(hash, accounts[5], { from: accounts[0] });
            let item = await storage.getItemForId(hash);

            assert.equal(item[0], accounts[5], "New owner should be Account 5");

            //remove e.g should for old owner
            let addError;

            try
            {
                let remove = await storage.removeDataItem(hash, { from: accounts[0] });
            } catch(error) {
                addError = error;
            }

            assert.notEqual(addError, undefined, 'Error must be thrown');

            //transfer back for further tests

            await storage.transferOwner(hash, accounts[0], { from: accounts[5] });
            item = await storage.getItemForId(hash);

            assert.equal(item[0], accounts[0], "New owner should be Account 0");

        });

        
        
        

        it("remove item complete", async function () {
            let addError;

            let remove = await storage.removeDataItem(hash, { from: accounts[0] });

            
            let itemDeleted = await storage.getItemForId(hash);
            let isDeleted = await storage.hasItemDeleted(accounts[0], hash);

            assert.equal(itemDeleted[0], "0x0000000000000000000000000000000000000000", "value should be zero or 0x0000000000000000000000000000000000000000");
            assert.isTrue(isDeleted,  "Excecpted deleted");
            
        });

        
        it("remove keyspace complete", async function () {

            let result = await storage.setStorage(accounts[0], hash3, root, keyname, size, replicationMode, [], { from: accounts[0] });
            let items = await storage.getIdsForKey(keyname);

            let remove = await storage.removeKey(keyname, { from: accounts[0] });

            let itemsAfterDelete = await storage.getIdsForKey(keyname);
            let itemsThatStillShouldExists = await storage.getIdsForKey(keyname2);
            let itemDeleted = await storage.hasItemDeleted(accounts[0], hash3);

            assert.isTrue(itemDeleted,  "Excecpted deleted");
            assert.notEqual(itemsThatStillShouldExists.length, 0 , "Keyname2 should still exists!")
            assert.equal(itemsAfterDelete.length, 0,  "There should be no items with this keyname");
        });

        
        

        
        
       /*
        it("check if item and deposit still exists after new storage contract still exists", async function () {

            //create new contract
            storage = await StorageNodeContract.new(vault.address, registrator.address);

            //set storage
            await storage.setStorageContract(foreverStorage.address);
            //add write right for storage
            await foreverStorage.addAdmin(storage.address);

            //add write to vault
            await vault.addAdmin(storage.address);


            //check reads

            //get item
            let item = await storage.getItemForId(hash);
            //get balance
            let balance = await storage.getDepositBalance(accounts[0]);

            assert.equal(item[1], accounts[0], "Excecpted owner is " + accounts[0]);
            assert.notEqual(balance.toNumber(), 0, "Excecpted balance should not be 0");
            

            //check writes
            await storage.deposit(accounts[0], { from: accounts[0], value: web3.toWei("1", 'ether') });

            let result = await storage.setStorage(accounts[0], hash2, root, keyname, size, replicationMode, [], { from: accounts[0] });

            let item2 = await storage.getItemForId(hash2);
            let idsArray = await storage.getIdsForAccount(accounts[0]);
            let costsCalculated = await costs.getStorageCosts(size, duration);

            assert.equal(idsArray[idsArray.length - 1].toLowerCase(), hash2.toLowerCase(), "Excecpted is in account list: " + idsArray[idsArray.length - 1].toLowerCase());
            assert.equal(item2[1], accounts[0], "Excecpted owner is " + accounts[0]);
            assert.equal(item2[2].toLowerCase(), root.toLowerCase(), "Excecpted merkle is " + root.toLowerCase());
            assert.equal(result.logs[0].event, "StorageItemAdded", "Expected StorageItemAdded event")
            assert.equal(result.logs[1].event, "StorageNodesSelected", "Expected StorageNodesSelected event")
        });
        */
       
        
    });


    

    /*
    it("add access key to storage item (from unkown user)", async function () {
        let addError;

        let hash = "18EE24150DCB1D96752A4D6DD0F20DFD8BA8C38527E40AA8509B7ADECF78F9C6";
        let root = "13C78C707B010724CD9E1F596B58246A2C829384FC8A8A4B49AA38B3FDDFC1C2";
        let keys = [];
        let category = "email";
        let replicationMode = 1;
        let privacy = 1;
        let duration = 100;
        let price = 100;

        let depositAmount = 10;

        let region = Regions.EUROPE;
        let bandwidth = Bandwidths.MEDIUM;

        let keyToAccess = "0xb3afa2ffce196c9b835a6e41c92b926db2dc2014";
        let encryptedSecret = "B897E454E5DAC59345D6B879207383D6E196D01DF9D09CB711671F7680A8B8C9";


        let endpoint = "http://localhost:8081/storage";

        let registratorResult = await storage.setRegistrator(registrator.address,{ from: accounts[0]});
        let registerResult = await registrator.registerNode(endpoint, bandwidth, region, { from: accounts[0], value: web3.toWei(depositAmount, 'ether') });
        let depositAmountResult = await storage.deposit({ from: accounts[0], value: web3.toWei(depositAmount, 'ether') });
        let result = await storage.initStorage(hash, root, keys, category, replicationMode, privacy, duration, price, { from: accounts[0] });
        
      
        try {
            //contract throws error here
            let resultAccess = await storage.addStorageAccessKey(hash, keyToAccess, encryptedSecret , { from: accounts[1] });
        } catch (error) {
            addError = error;
        }
        
      
        assert.notEqual(addError, undefined, 'Error must be thrown');
    });
    



    
    it("add storage proof signature", async function () {
        let addError;

        let hash = "18EE24150DCB1D96752A4D6DD0F20DFD8BA8C38527E40AA8509B7ADECF78F9C6";
        let root = "13C78C707B010724CD9E1F596B58246A2C829384FC8A8A4B49AA38B3FDDFC1C2";
        let keys = [];
        let category = "email";
        let replicationMode = 1;
        let privacy = 1;
        let duration = 100;
        let price = 100;

        let depositAmount = 10;

        let region = Regions.EUROPE;
        let bandwidth = Bandwidths.MEDIUM;
        let endpoint = "http://localhost:8081/storage";


        let signature = '0xaf5dae11ddfb9d72f0b5413366905cfe04f831af8e496392cc803e2f408175cf6b640c1eea6982d4dac485b37aada8378e2a7b963cd1cd56bd3780d0dafa6c911b';
        signature = signature.substr(2); //remove 0x
        const r = '0x' + signature.slice(0, 64)
        const s = '0x' + signature.slice(64, 128)
        const v = '0x' + signature.slice(128, 130)
        const v_decimal = web3.toDecimal(v)
    

        let registratorResult = await storage.setRegistrator(registrator.address,{ from: accounts[0]});
        let registerResult = await registrator.registerNode(endpoint, bandwidth, region, { from: accounts[0], value: web3.toWei(depositAmount, 'ether') });
        let depositAmountResult = await storage.deposit({ from: accounts[0], value: web3.toWei(depositAmount, 'ether') });
        let result = await storage.initStorage(hash, root, keys, category, replicationMode, privacy, duration, price, { from: accounts[0] });
        
        let resultProofAdd = await storage.addStorageProof(hash, signature, v_decimal,r,s , { from: accounts[0] });
        
      
        assert.equal(resultAccess.logs[0].event, "StorageProofAdded", "Expected StorageProofAdded event")
    });
    */
    

});