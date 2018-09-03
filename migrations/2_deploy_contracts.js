var StorageNodeContract = artifacts.require("StorageNodeContract");
var NodeRegistrator = artifacts.require("NodeRegistrator");
var VaultManager = artifacts.require("VaultManager");
var StorageCostsContract = artifacts.require("StorageCostsContract");
var ForeverStorage = artifacts.require("ForeverStorage");

module.exports = function(deployer) {
  deployer.deploy(VaultManager)
  .then(function() {
    return deployer.deploy(StorageCostsContract);
  })
  .then(function() {
    return deployer.deploy(ForeverStorage);
  })
  .then(function() {
    return deployer.deploy(NodeRegistrator);
  })
  .then(async () => {
    var nodeRegistrator = await NodeRegistrator.deployed();
    var foreverStorage = await ForeverStorage.deployed();
    await foreverStorage.addAdmin(nodeRegistrator.address);
  })
  .then(async () => {
    var nodeRegistrator = await NodeRegistrator.deployed();
    var foreverStorage = await ForeverStorage.deployed();
    await nodeRegistrator.setStorage(foreverStorage.address);
  })
  .then(function() {
    return deployer.deploy(StorageNodeContract, VaultManager.address, NodeRegistrator.address);
  })
  .then(async () => {
    var vault = await VaultManager.deployed();
    await vault.transferOperator(StorageNodeContract.address);
  });
};