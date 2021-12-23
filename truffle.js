var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "pull suffer congress capital steel globe still bonus slush cherry strong satisfy";

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: '*',
      gas: 9999999
    }
  },
  compilers: {
    solc: {
      version: "0.4.25"
    }
  }
};