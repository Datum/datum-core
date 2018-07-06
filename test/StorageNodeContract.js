const web3 = global.web3;
const StorageNodeContract = artifacts.require('StorageNodeContract');
const VaultManager = artifacts.require('VaultManager');
const StorageCostsContract = artifacts.require('StorageCostsContract');
const NodeRegistrator = artifacts.require('NodeRegistrator');

contract('StorageNodeContract', function (accounts) {
    let storage;
    let vault;
    let registrator;
    let costs;


    //test params
    let hash = "0x18EE24150DCB1D96752A4D6DD0F20DFD8BA8C38527E40AA8509B7ADECF78F9C6";
    let root = "0x13C78C707B010724CD9E1F596B58246A2C829384FC8A8A4B49AA38B3FDDFC1C2";
    let secret = "0x5d521323580bc303b1dd9cf4f9dc3a90049a2a5aceb5e005233df99fac70d0edad1749cfee8744507992fa14ff682bc56a1955c3697f2b50ee409476cf6f75b8782bcc2fd2de3979d0f7e1285e990487599bf93686f165a5e47ec79e3089c821ac097e437caed37c43fa1a6625cab619a302da47ea50be6bba0124d3a893982f260fc8b0eb8d87ad8d88d25b76bc57f3e7";
    let secret2 = "0x7fe5b21c5edb868e1494f30813864653041ec18e051b1670b0437beee0ca1d890d32e2dcd7498ae298557a66325ae8a6be0347189915075577bc3059adff2c25cffcecccd984f44a8567fa158215d6df86031b1d9c235fd5a34383ff26a63dc81ea32cb52087df04fef83e0ee3e85cc7ddce9adfe3695ea16b2ee52a6bec2c78aae8ff1615ff59192bf8b2de07658ef3a2";
    let size = 1023334;
    let keyname = "TEST";
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



    //create new smart contract instance before each test method
    beforeEach(async function () {
        storage = await StorageNodeContract.new();
        costs = await StorageCostsContract.new();
    });


    it("set new vault manager (from operator)", async function () {
        let existingVault = await storage.vault.call();

        let newVault = await VaultManager.new();
        let result = await storage.setVaultManager(newVault.address, { from: accounts[0] });
        let newVaultStored = await storage.vault.call();

        assert.notEqual(existingVault, newVaultStored, 'Vault must be changed');
        assert.equal(newVaultStored, newVault.address, "Expected new vault set")
    });

    it("set new vault manager (from unknown account)", async function () {
        let addError;

        try {
            //contract throws error here
            let newVault = await VaultManager.new();
            let result = await storage.setVaultManager(newVault.address, { from: accounts[1] });
        } catch (error) {
            addError = error;
        }

        assert.notEqual(addError, undefined, 'Error must be thrown');
    });


    it("set new registrator (from operator)", async function () {
        let existsingRegistrator = await storage.registrator.call();

        let newRegistrator = await NodeRegistrator.new();
        let result = await storage.setRegistrator(newRegistrator.address, { from: accounts[0] });
        let newRegistratorStored = await storage.registrator.call();

        assert.notEqual(existsingRegistrator, newRegistratorStored, 'Vault must be changed');
        assert.equal(newRegistratorStored, newRegistrator.address, "Expected new vault set")
    });

    it("set new registrator manager (from unknown account)", async function () {
        let addError;

        try {
            //contract throws error here
            let newRegistrator = await NodeRegistrator.new();
            let result = await storage.setRegistrator(newRegistrator.address, { from: accounts[1] });
        } catch (error) {
            addError = error;
        }


        assert.notEqual(addError, undefined, 'Error must be thrown');
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
        let depositAmountResult = await storage.deposit({ from: accounts[0], value: web3.toWei("1", 'ether') });
        assert.equal(depositAmountResult.logs[0].event, "Deposit", "Expected Deposit event")
    });


    describe('storage tests', function () {

        it("init storage node (providing deposit amount)", async function () {
            let addError;

            let depositAmountResult = await storage.deposit({ from: accounts[0], value: web3.toWei("10", 'ether') });
            let result = await storage.setStorage(hash, root, keyname, size, duration, replicationMode, privacy, secret, { from: accounts[0] });

            let item = await storage.getItemForId(hash);
            let idsArray = await storage.getIdsForAccount(accounts[0]);
            let encSecret = await storage.getEncryptedSecret(hash);
            let lockedBalance = await storage.getLockedBalanceForId(accounts[0], hash);
            let costsCalculated = await costs.getStorageCosts(size, duration);

            assert.isAtLeast(lockedBalance.toNumber(), costsCalculated, "Excecpted locked amount not 0");
            assert.equal(encSecret, secret, "Excecpted secret is " + secret);
            assert.equal(idsArray[idsArray.length - 1].toLowerCase(), hash.toLowerCase(), "Excecpted is in account list: " + idsArray[idsArray.length - 1].toLowerCase());
            assert.equal(item[0], accounts[0], "Excecpted owner is " + accounts[0]);
            assert.equal(item[1].toLowerCase(), hash.toLowerCase(), "Excecpted hash is " + hash.toLowerCase());
            assert.equal(item[2].toLowerCase(), root.toLowerCase(), "Excecpted merkle is " + root.toLowerCase());
            assert.equal(result.logs[0].event, "StorageInitialized", "Expected StorageInitialized event")
            assert.equal(result.logs[1].event, "StorageItemAdded", "Expected StorageItemAdded event")
        });


        it("init storage node (providing insufficient deposit amount)", async function () {
            let addError;

            //set big size
            let bigSize = 156465456651;

            try {
                //contract throws error here
                let depositAmountResult = await storage.deposit({ from: accounts[0], value: web3.toWei("1", 'ether') });
                let result = await storage.setStorage(hash, root, keyname, bigSize, duration, replicationMode, privacy, secret, { from: accounts[0] });
            } catch (error) {
                addError = error;
            }

            assert.notEqual(addError, undefined, 'Error must be thrown');
        });


        it("add access key to storage item", async function () {
            let addError;

            let depositAmountResult = await storage.deposit({ from: accounts[0], value: web3.toWei("10", 'ether') });
            let result = await storage.setStorage(hash, root, keyname, size, duration, replicationMode, privacy, secret, { from: accounts[0] });

            //add access
            let resultAccess = await storage.addAccess(hash, accounts[1], secret2, { from: accounts[0] });

            let item = await storage.getItemForId(hash);
            let idsArray = await storage.getIdsForAccount(accounts[0]);
            let encSecret2 = await storage.getEncryptedSecret(hash, { from: accounts[1] });
            
            assert.equal(encSecret2, secret2, "Excecpted secret is " + secret2);
        });


        it("remove access key to storage item", async function () {
            let addError;

            let depositAmountResult = await storage.deposit({ from: accounts[0], value: web3.toWei("10", 'ether') });
            let result = await storage.setStorage(hash, root, keyname, size, duration, replicationMode, privacy, secret, { from: accounts[0] });

            //add access
            let resultAccess = await storage.addAccess(hash, accounts[1], secret2, { from: accounts[0] });

            let item = await storage.getItemForId(hash);
            let idsArray = await storage.getIdsForAccount(accounts[0]);
            let idsArray2 = await storage.getIdsForAccount(accounts[1]);
            let encSecret = await storage.getEncryptedSecret(hash, { from: accounts[0] });
            let encSecret2 = await storage.getEncryptedSecret(hash, { from: accounts[1] });
            let canAccess = await storage.canKeyAccessData(hash, accounts[1]);

            
            assert.isTrue(canAccess,  "Excecpted can access data");

            //remove access 
            let remove = await storage.removeStorageAccessKey(hash, accounts[1], { from: accounts[0] });
            let encSecret3 = await storage.getEncryptedSecret(hash, { from: accounts[1] });
            let canAccessAfter = await storage.canKeyAccessData(hash, accounts[1]);

            assert.isFalse(canAccessAfter, "0x", "Excecpted can't access data");
            assert.equal(encSecret3, "0x", "Excecpted secret is 0x");
            assert.equal(remove.logs[0].event, "StorageItemPublicKeyRemoved", "Expected StorageItemPublicKeyRemoved event")

        });


        it("remove item complete", async function () {
            let addError;

            let depositAmountResult = await storage.deposit({ from: accounts[0], value: web3.toWei("10", 'ether') });
            let result = await storage.setStorage(hash, root, keyname, size, duration, replicationMode, privacy, secret, { from: accounts[0] });

            //add access
            let resultAccess = await storage.addAccess(hash, accounts[1], secret2, { from: accounts[0] });

            let item = await storage.getItemForId(hash);
            let idsArray = await storage.getIdsForAccount(accounts[0]);
            let idsArray2 = await storage.getIdsForAccount(accounts[1]);
            let encSecret = await storage.getEncryptedSecret(hash, { from: accounts[0] });
            let encSecret2 = await storage.getEncryptedSecret(hash, { from: accounts[1] });
            let canAccess = await storage.canKeyAccessData(hash, accounts[1]);

            
            assert.isTrue(item[9],  "Excecpted exists");

            //remove access 
            let remove = await storage.removeDataItem(hash, { from: accounts[0] });
            let itemDeleted = await storage.getItemForId(hash);

            assert.isFalse(itemDeleted[9],  "Excecpted deleted");
        });

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
    */



    /*
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