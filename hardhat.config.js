require("@nomiclabs/hardhat-waffle");
const fs = require("fs")
require('dotenv').config();

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

function mnemonic() {
  return process.env.PRIVATE_KEY;
}
module.exports = {
  solidity: {
    version:"0.8.0",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    localhost: {
      url: "http://localhost:8545",
    },
    rinkeby: {
      url: "https://rinkeby.infura.io/v3/0aae8358bfe04803b8e75bb4755eaf07", //<---- YOUR INFURA ID! (or it won't work)
      accounts: [
      mnemonic()
      ],
    },
    kovan: {
      url: "https://kovan.infura.io/v3/0aae8358bfe04803b8e75bb4755eaf07", //<---- YOUR INFURA ID! (or it won't work)
      accounts: [
        mnemonic()
      ],
    },
    mainnet: {
      url: "https://mainnet.infura.io/v3/0aae8358bfe04803b8e75bb4755eaf07", //<---- YOUR INFURA ID! (or it won't work)
      accounts: [
        mnemonic()
      ],
    },
    ropsten: {
      url: "https://ropsten.infura.io/v3/0aae8358bfe04803b8e75bb4755eaf07", //<---- YOUR INFURA ID! (or it won't work)
      accounts: [
        mnemonic()
      ],
    },
  }
};
