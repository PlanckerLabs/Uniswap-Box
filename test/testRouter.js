const fs = require("fs");
const { BigNumber } = require("ethers");
const addressConfJson = require("../address.json");
const Out = artifacts.require("Out");
const Router = artifacts.require("Router");
const TickLens = artifacts.require("TickLens");

module.exports = async (callback) => {
    try {
        await run()
        callback()
    } catch (e) {
        callback(e)
    }
}

async function run() {
    const router = await Router.at(addressConfJson.Router);
    console.log("Router address :", router.address);

    await positions(router);
}

async function positions(router){
    const pos = await router.positions(2117);
    console.log(pos[5].toString());
    console.log(pos[6].toString());
}