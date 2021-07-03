const Out = artifacts.require("Out")

module.exports = async (callback) => {
 try {
  await run()
  callback()
 } catch (e) {
  callback(e)
 }
}

async function run() {
 
 //////////////////////////////////////////////////////////// 
 const outContract = await Out.at('0x3e22c6b33Eab5713F243EE7E1b2ED8dadc9C3A06')
 console.log("-当前合约地址：", outContract.address)

 await outContract.create(dai_ropsten_address,weth_ropsten_address,"500","500",user_address,"1900","2000","5")
}