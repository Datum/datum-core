module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  networks: {
    development: {
      host: "localhost",
      port: 9545,
      gas: 7770551,
      network_id: "*" // Match any network id
    },
    live: {
      host: "localhost",
      port: 8545,
      gas: 4800000,
      network_id: "51515" // Match any network id
    }
  },
  solc: {
    optimizer: {
        enabled: true,
        runs: 200
    }
  }
};
