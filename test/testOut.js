const fs = require("fs");
const bigNumber = require("bignumber.js")
const addressConfJson = require("../address.json");
const Out = artifacts.require("Out");
\
module.exports = async (callback) => {
	try {
		await run()
		callback()
	} catch (e) {
		callback(e)
	}
}

async function run() {
	const out = await Out.at(addressConfJson.Out);
	console.log("out address :", out.address);

	// 价格函数
	// await getPrice(out);
	
	// 策略信息
	let strategyId = 0;
	// await getStrategy(out,strategyId);

	// 创建策略
	// await create(out);

	// 所有策略id
	// await getUserInfo(out);

	// tick 信息
	// await getStrategyInfo(out,strategyId);

	// 返回用户自己的所有策略信息
	let ids = [0,1,2];
	// await getAllStrategy(out,ids);

	// 检测并执行策略
	await execute(out);

	// 提取策略资金
	let to = "0xF9758dB6571Cfe61e6eB9146D82A0f0FF7ACBc45";
	// await withdraw(out,ids,to);

}

async function getPrice(out) {

	const price = await out.getPrice("0x4DBCdF9B62e891a7cec5A2568C3F4FAF9E8Abe2b", "0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984", 500);
	console.log("价格", price);


}

async function create(out) {
	// 创建策略
	let tokenA = "0xc778417E063141139Fce010982780140Aa0cD5Ab";
	let tokenB = "0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984";
	let fee = 500;
	let amount = new bigNumber(0.5).times(1e18);
	let to = "0xF9758dB6571Cfe61e6eB9146D82A0f0FF7ACBc45";
	let tickMin = new bigNumber(1).times(1e18);
	let tickMax = new bigNumber(2).times(1e18);
	let tickCount = 6;
	let a = await out.create(tokenA, tokenB, fee, amount, to, tickMin, tickMax, tickCount);
	console.log("创建策略：",a);
}

async function getStrategy(out,strategyId){
	// 策略信息
	let a = await out.getStrategy(strategyId);
	console.log("策略归属：",a[0]);
	console.log("策略A币:",a[1]);
	console.log("策略B币：",a[2]);
	console.log("策略费率：",a[3]);
	console.log("初始投入：",a[4]);
	console.log("交换A量：",a[5]);
	console.log("交换B量：",a[6]);
	console.log("最小TICK：",a[7]);
	console.log("最大TICK：",a[8]);
	console.log("TICK数量：",a[9]);
}

async function getUserInfo(out){
	// 所有策略ID
	let a = [];
	a = await out.getUserInfo("0xF9758dB6571Cfe61e6eB9146D82A0f0FF7ACBc45");
	console.log("所有策略id：",a.toString());

}

async function getStrategyInfo(out,strategyId) {
	// 每个策略的具体挂单信息(tick详细信息)
	let b = [];
	b = await out.getStrategyInfo(strategyId);
	console.log("tick信息:",b.toString());
}

async function getAllStrategy(out,ids){
	let a = [];
	a = await out.getAllStrategy(ids);
	console.log("返回用户自己的所有策略信息:",a)
}

async function execute(out) {
	console.log("检测策略并执行已经满足条件的策略：",await out.execute())
}

async function withdraw(out,ids,to) {
	console.log("提取策略资金：",await out.withdraw(ids,to));
}