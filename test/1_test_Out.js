const Out = artifacts.require("Out");
const bigNumber = require("bignumber.js")
const fs = require("fs")

const timestamp = Math.ceil(new Date().getTime() / 1000)

require('chai')
  .use(require('chai-as-promised'))
  .should()

function tokens(n) {
    return web3.utils.toWei(n, 'ether');
  }

contract('Out', (owner,investor) => {

})

before(async () => {
    OutContract = await Out.new()
})

describe('creat strategy', async () => {
    it('has token', async () => {
        const 
    })
})
async function run() {
// 括号中是合约的部署地址
  const pairpool = await Out.at(
    "0xfb5AE0cCB29c456B741B4595A5c11514cB573b93",
  )
  console.log("rainbow 合约地址 ", pairpool.address)

  await getAmountsOut(pairpool)
  // await addLiquidity(pairpool)
}