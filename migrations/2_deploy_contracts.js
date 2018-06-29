var StorageNodeContract = artifacts.require("StorageNodeContract");
var NodeRegistrator = artifacts.require("NodeRegistrator");
var VaultManager = artifacts.require("VaultManager");

module.exports = function(deployer) {
  deployer.deploy(NodeRegistrator).then(function() {
    deployer.deploy(StorageNodeContract);
  });
};