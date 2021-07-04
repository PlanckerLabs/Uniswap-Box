const fs = require("fs");
const { BigNumber } = require("ethers");
const addressConfJson = require("../address.json");
const Out = artifacts.require("Out");
const Router = artifacts.require("Router");
const TickLens = artifacts.require("TickLens");
const Pool = artifacts.require("../interfaces/IUniswapV3PoolState");

module.exports = async (callback) => {
    try {
        await run()
        callback()
    } catch (e) {
        callback(e)
    }
}

async function run() {
    const tick = await TickLens.at(addressConfJson.TickLens);
    console.log("TickLens address :", tick.address);

    await getPoolAddress(tick);
    // await getPopulatedTicksInWord(tick);
    // console.log(getTick(Math.ceil(-887272 / 60) * 60,60));

}

async function getPopulatedTicksInWord(tick) {
    const poolAddr = await tick.getPoolAddress("0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984", "0xc778417E063141139Fce010982780140Aa0cD5Ab", 3000);
    // for (var i = 100; i >= 0; i--) {
    //     const res = await tick.getPopulatedTicksInWord(poolAddr, i);
    //     console.log(res);
    // }
    // Math.ceil(-887272 / tickSpacing) * tickSpacing
    // Math.floor(887272 / tickSpacing) * tickSpacing
    const res = await tick.getPopulatedTicksInWord(poolAddr,0);
    console.log(res);
    console.log(getTick(Math.ceil(-887272 / 60) * 60,60));
    console.log("池子地址:", poolAddr);
}

async function getPoolAddress(tick) {
    let tokenA = "0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984";//0xc778417E063141139Fce010982780140Aa0cD5Ab
	let tokenB = "0xc778417E063141139Fce010982780140Aa0cD5Ab";//0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984
    const poolAddr = await tick.getPoolAddress(tokenA, tokenB, 3000);
    console.log("池子地址:", poolAddr);
}

function getTick(tick,tickSpacing){
    const intermediate = BigNumber.from(tick).div(tickSpacing);
    return intermediate.lt(0) ? intermediate.add(1).div(BigNumber.from(2).pow(8)).sub(1) : intermediate.shr(8);
}