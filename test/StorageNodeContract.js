const web3 = global.web3;
const StorageNodeContract = artifacts.require('StorageNodeContract');
const VaultManager = artifacts.require('VaultManager');
const NodeRegistrator = artifacts.require('NodeRegistrator');

contract('StorageNodeContract', function (accounts) {
    let storage;
    let vault;
    let registrator;

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
        vault = await VaultManager.new();
        registrator = await NodeRegistrator.new();
        storage = await StorageNodeContract.new();
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
        let depositAmountResult = await storage.deposit({ from: accounts[0], value: web3.toWei(1, 'ether') });

        assert.equal(depositAmountResult.logs[0].event, "Deposit", "Expected Deposit event")
    });

      
   


    it("init storage node (without deposit amount)", async function () {
        let addError;

        let hash = "18EE24150DCB1D96752A4D6DD0F20DFD8BA8C38527E40AA8509B7ADECF78F9C6";
        let root = "13C78C707B010724CD9E1F596B58246A2C829384FC8A8A4B49AA38B3FDDFC1C2";
        let keys = [];
        let category = "email";
        let replicationMode = 1;
        let privacy = 1;
        let duration = 100;
        let price = 100;

        try {
            //contract throws error here
            let result = await storage.initStorage(hash, root, keys, category, replicationMode, privacy, duration, price, { from: accounts[0] });
        } catch (error) {
            addError = error;
        }
        
      
        assert.notEqual(addError, undefined, 'Error must be thrown');
    });
    

    it("init storage node (providing deposit amount)", async function () {
        let addError;

        let hash = "0xe28924dfddef2bf2a65160d28e8f685ba9dd5d7b64b3ba25ce99094a24caa2c8";
        let root = "13C78C707B010724CD9E1F596B58246A2C829384FC8A8A4B49AA38B3FDDFC1C2";
        let key = "13C78C707B010724CD9E1F596B58246A2C829384FC8A8A4B49AA38B3FDDFC1C2";
        let secret ="13C78C707B010724CD9E1F596B58246A2C829384FC8A8A4B49AA38B3FDDFC1C2";
        let metadata = '{"userId":1,"id":1,"title":"sunt aut facere repellat provident occaecati excepturi optio reprehenderit","body":"quia et suscipit suscipit recusandae consequuntur expedita et cum reprehenderit molestiae ut ut quas totam nostrum rerum est autem sunt rem eveniet architecto"}';
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

        let registratorResult = await storage.setRegistrator(registrator.address,{ from: accounts[0]})
        let registerResult = await registrator.registerNode(endpoint, bandwidth, region, { from: accounts[0], value: web3.toWei(depositAmount, 'ether') });
        let depositAmountResult = await storage.deposit({ from: accounts[0], value: web3.toWei(depositAmount, 'ether') });
        let result = await storage.initStorage(hash, key, category, metadata, replicationMode, privacy, duration,   { from: accounts[0] });

        assert.equal(result.logs[0].event, "StorageInitialized", "Expected StorageInitialized event")
        assert.equal(result.logs[1].event, "StorageItemAdded", "Expected StorageItemAdded event")
        assert.equal(result.logs[2].event, "StorageEndpointSelected", "Expected StorageEndpointSelected event")
    });

    

    it("add access key to storage item (from orignal owner)", async function () {


        let addError;

        let hash = "0xe28924dfddef2bf2a65160d28e8f685ba9dd5d7b64b3ba25ce99094a24caa2c8";
        let root = "13C78C707B010724CD9E1F596B58246A2C829384FC8A8A4B49AA38B3FDDFC1C2";
        let key = "13C78C707B010724CD9E1F596B58246A2C829384FC8A8A4B49AA38B3FDDFC1C2";
        let secret ="13C78C707B010724CD9E1F596B58246A2C829384FC8A8A4B49AA38B3FDDFC1C2";
        let metadata = '{"userId":1,"id":1,"title":"sunt aut facere repellat provident occaecati excepturi optio reprehenderit","body":"quia et suscipit suscipit recusandae consequuntur expedita et cum reprehenderit molestiae ut ut quas totam nostrum rerum est autem sunt rem eveniet architecto"}';
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

        let registratorResult = await storage.setRegistrator(registrator.address,{ from: accounts[0]})
        let registerResult = await registrator.registerNode(endpoint, bandwidth, region, { from: accounts[0], value: web3.toWei(depositAmount, 'ether') });
        let depositAmountResult = await storage.deposit({ from: accounts[0], value: web3.toWei(depositAmount, 'ether') });
        let result = await storage.initStorage(hash, key, category, metadata, replicationMode, privacy, duration,   { from: accounts[0] });
        let resultAccess = await storage.addStorageAccessKey(hash, accounts[0], '0x81da3a7d69a3fa5592b610edeef41d58042dc2729f73935b6793fecd12bf4abc6dce5167aa19118ba2c75e2f3bf9f01c4d3687e1c08' , { from: accounts[0] });
      
        assert.equal(resultAccess.logs[0].event, "StorageItemPublicKeyAdded", "Expected StorageItemPublicKeyAdded event")

        //assert.equal(result.logs[0].event, "StorageInitialized", "Expected StorageInitialized event")
        //assert.equal(result.logs[1].event, "StorageItemAdded", "Expected StorageItemAdded event")
        //assert.equal(result.logs[2].event, "StorageEndpointSelected", "Expected StorageEndpointSelected event")


     

      
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