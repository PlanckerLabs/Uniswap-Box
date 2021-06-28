const Web3 = require('web3');
const contractFile = require('./eth-usdt.json')

const web3 = new Web3(new Web3.providers.HttpProvider('https://mainnet.infura.io/v3/ea105d55c4394f4fb7b58d29c877e797'));
address = "0x8ad599c3A0ff1De082011EFDDc58f1908eb6e6D8";
const first_time = 1;
const second_time = 10;

const contract = new web3.eth.Contract(contractFile,address)
const get_price = setInterval(async() => {

   //获取tick数据
let result = true;
 //获取tick数据
 if (result) {
    result = false;
    contract.methods.observe([first_time,second_time]).call().then(ticks=>{
    result = true;
    tick_price = (ticks['tickCumulatives'][0] - ticks['tickCumulatives'][1])/(second_time - first_time)
    eth_price = Math.pow(10,12)/Math.pow(1.0001,tick_price)
    console.log(eth_price);
   });
 }
},5000)









