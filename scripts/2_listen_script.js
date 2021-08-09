const ethers = require('ethers');
const fs = require("fs");
const bigNumber = require("bignumber.js")
require('dotenv').config()
const out = require('../artifacts/contracts/Out.sol/Out.json')

const rinkeby_address = "0x1b879da6Fc302C4a4e4dAEbd20e3C8db51F1722b";
const web3Provider = new ethers.providers.InfuraProvider("rinkeby", "0aae8358bfe04803b8e75bb4755eaf07")
console.log(web3Provider);
const privatekey = process.env.PRIVATE_KEY;

const account_from = {
    privateKey: privatekey
}

//create wallet

let wallet = new ethers.Wallet(account_from.privateKey,web3Provider);
console.log(wallet.address);
let contract = new ethers.Contract(rinkeby_address,out.abi,web3Provider)
console.log(contract.address);
//connect wallet
let contractWithSigner = contract.connect(wallet);

async function create(){
    console.log("================================Listen to events");
    contract.on("depositMoney",(to,amountIn) => {
        console.log(to, amountIn)
    })
    let tokenA = "0x1f9840a85d5af5bf1d1762f925bdaddc4201f984";
    let tokenB = "0xc778417e063141139fce010982780140aa0cd5ab";//0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984
    let fee = 3000;
    let amount = 10000;
    let to = "0xF9758dB6571Cfe61e6eB9146D82A0f0FF7ACBc45";
    let ticks = [60, 240, 480];
    let Str = await contractWithSigner.create(tokenA, tokenB, fee, amount, to, ticks);
    await Str.wait();
    console.log("创建策略：", Str);

}

create();


