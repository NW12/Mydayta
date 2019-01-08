
var HDWalletProvider = require("truffle-hdwallet-provider");

var infura_apikey = "7a30131ad79744288df9ea8707597462";
var mnemonic = "theme road gold hint seat abuse resemble busy organ smoke today fortune";

module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*" // Match any network id
    },
    rinkeby: {
      provider: new HDWalletProvider(mnemonic, "https://rinkeby.infura.io/"+infura_apikey),
      network_id: 4,
      gas: 7000000
    }, 
    ropsten: {
      provider: new HDWalletProvider(mnemonic, "https://ropsten.infura.io/"+infura_apikey),
      network_id: 3,
      gas: 7000000
    },
   MainNet: {
      provider: new HDWalletProvider(mnemonic, "https://mainnet.infura.io/"+infura_apikey),
      network_id: 1,
      gas: 7000000
    }
  }
};