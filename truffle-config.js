const fs = require('fs')
const HDWalletProvider = require('truffle-hdwallet-provider')

const mnemonic = fs.readFileSync('./sk.txt').toString().trim()

module.exports = {
  // Uncommenting the defaults below
  // provides for an easier quick-start with Ganache.
  // You can also follow this format for other networks;
  // see <http://truffleframework.com/docs/advanced/configuration>
  // for more details on how to specify configuration options!
  //
  compilers: {
    solc: {
      version: '0.8.0',
	  settings: {		  // See the solidity docs for advice about optimization and evmVersion
		optimizer: {
			enabled: true,
			runs: 200
		}
		//,
		//  evmVersion: "byzantium"
		}	  
    },
  },
  networks: {
    //  development: {
    //    host: "127.0.0.1",
    //    port: 7545,
    //    network_id: "*"
    //  },
    //  test: {
    //    host: "127.0.0.1",
    //    port: 7545,
    //    network_id: "*"
    //  }
    //},
    ropsten: {
      provider: () =>
        new HDWalletProvider(
          mnemonic,
          'https://ropsten.infura.io/v3/0aae8358bfe04803b8e75bb4755eaf07'
        ),
      network_id: '*',
      gas: 30000001,
      gasPrice: 1000000000,
    },
    kovan: {
      provider: () =>
        new HDWalletProvider(
          mnemonic,
          'https://kovan.infura.io/v3/0aae8358bfe04803b8e75bb4755eaf07'
        ),
      network_id: '*',
    },
    rinkeby: {
      provider: () =>
        new HDWalletProvider(
          mnemonic,
          'https://rinkeby.infura.io/v3/0aae8358bfe04803b8e75bb4755eaf07'
        ),
      network_id: '*',
      gas: 3000000,
      gasPrice: 10000000000,
    },
  },
}
