// const Out = artifacts.require("Out");
const bigNumber = require("bignumber.js")
const fs = require("fs")
const Web3 = require('web3');
const Outabi = require("../build/contracts/Out.json")
daiabi = require("./daiabi.json")
// require('chai')
//   .use(require('chai-as-promised'))
//   .should()


//1、策略检查

//Out合约地址

Out_ropsten_address = "0x3e22c6b33Eab5713F243EE7E1b2ED8dadc9C3A06"
weth_ropsten_address = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
dai_ropsten_address = "0xad6d458402f60fd3bd25163575031acdce07538d"
user_address = "0x832946E630142c9E801B49C6186bCe7d3bF50ABe"

// 时间戳
const timestamp = Math.ceil(new Date().getTime() / 1000)

const web3 = new Web3(new Web3.providers.HttpProvider('https://ropsten.infura.io/v3/ea105d55c4394f4fb7b58d29c877e797'))
const Out_contract = new web3.eth.Contract(Outabi['abi'],Out_ropsten_address)
const dai = new web3.eth.Contract(daiabi,dai_ropsten_address)
// console.log(Out_contract);

const Creat_Strategy = async () => {
  strategy = await Out_contract.methods.create(dai_ropsten_address,weth_ropsten_address,500,500,user_address,1900,2000,5).call()
  console.log(strategy);
  const dai_balance = await dai.methods.balanceOf(Out_ropsten_address).call()
  console.log(dai_balance);
}


Creat_Strategy()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
//函数检查

// function tokens(n) {
//     return web3.utils.toWei(n, 'ether');
//   }

// contract('Out', (owner,investor) => {

// })

// before(async () => {
//     OutContract = await Out.new()
// })

// describe('creat strategy', async () => {
//     it('has token', async () => {
//         const 
//     })
// })
// async function run() {
// // 括号中是合约的部署地址
//   const pairpool = await Out.at(
//     "0xfb5AE0cCB29c456B741B4595A5c11514cB573b93",
//   )
//   console.log("rainbow 合约地址 ", pairpool.address)

//   await getAmountsOut(pairpool)
//   // await addLiquidity(pairpool)
// }