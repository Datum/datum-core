var StorageNodeContract = artifacts.require("StorageNodeContract");
var NodeRegistrator = artifacts.require("NodeRegistrator");
var VaultManager = artifacts.require("VaultManager");
var VaultManagerNodeRegistrator = artifacts.require("VaultManager");
var StorageCostsContract = artifacts.require("StorageCostsContract");
var ForeverStorage = artifacts.require("ForeverStorage");
var StorageProxyContract = artifacts.require("StorageProxyContract");
var StorageKeys = artifacts.require("StorageKeys");
var StorageData = artifacts.require("StorageData");
var NodeRegistratorData = artifacts.require("NodeRegistratorData");

module.exports = function(deployer) {
  deployer.deploy(VaultManager)
  .then(function() {
    return deployer.deploy(StorageCostsContract);
  })
  .then(function() {
    return deployer.deploy(ForeverStorage);
  })
  .then(function() {
    return deployer.deploy(StorageKeys);
  })
  .then(function() {
    return deployer.deploy(VaultManagerNodeRegistrator);
  })
  .then(async function() {
    var foreverStorage = await ForeverStorage.deployed();
    var storageKeys = await StorageKeys.deployed();
    return deployer.deploy(StorageData,foreverStorage.address, storageKeys.address);
  })
  .then(async function() {
    var foreverStorage = await ForeverStorage.deployed();
    var storageKeys = await StorageKeys.deployed();
    return deployer.deploy(NodeRegistratorData,foreverStorage.address, storageKeys.address);
  })
  .then(async () => {
    var storageKeys = await StorageKeys.deployed();
    var nodeData = await NodeRegistratorData.deployed();
    var vaultManagerNode = await VaultManagerNodeRegistrator.deployed();
    return deployer.deploy(NodeRegistrator, vaultManagerNode.address, StorageKeys.address, nodeData.address);
  })
  .then(async function() {
    var vault = await VaultManager.deployed();
    var nodeRegistrator = await NodeRegistrator.deployed();
    var storageKeys = await StorageKeys.deployed();
    var storageData = await StorageData.deployed();
    var foreverStorage = await ForeverStorage.deployed();
    return deployer.deploy(StorageNodeContract, vault.address, nodeRegistrator.address, foreverStorage.address, storageKeys.address, storageData.address);
  })
  .then(async () => { 
    var storage = await StorageNodeContract.deployed();
    return deployer.deploy(StorageProxyContract, storage.address);
  })
  .then(async () => {
    var vault = await VaultManager.deployed();
    var vaultNode = await VaultManagerNodeRegistrator.deployed();
    var storage = await StorageNodeContract.deployed();
    var foreverStorage = await ForeverStorage.deployed();
    var nodeRegistrator = await NodeRegistrator.deployed();
    var storageData = await StorageData.deployed();
    var nodeData = await NodeRegistratorData.deployed();

    await vault.addAdmin(storage.address);
    await vaultNode.addAdmin(nodeRegistrator.address);
    await foreverStorage.addAdmin(storage.address);
    await foreverStorage.addAdmin(nodeRegistrator.address);
    await foreverStorage.addAdmin(storageData.address);
    await foreverStorage.addAdmin(nodeData.address);

    await storageData.addAdmin(storage.address);
    await nodeData.addAdmin(nodeRegistrator.address);
  })
  /*
  .then(async function() {
    var storage = await StorageNodeContract.deployed();
    return deployer.deploy(StorageProxyContract, storage.address);
  })
  */
};