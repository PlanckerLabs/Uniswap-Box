const fs = require("fs");
const bigNumber = require("bignumber.js")
const addressConfJson = require("../address.json");
const Out = artifacts.require("Out");
const Router = artifacts.require("Router");
const TickLens = artifacts.require("TickLens");
const DateNow = Date.parse(new Date());

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

	// await getTick(out);

	// 所有策略id
	// await getUserInfo(out);

	// tick 信息
	// await getStrategyInfo(out,0);

	// 返回用户自己的所有策略信息
	let ids = [0];
	// await getAllStrategy(out,ids);

	// 检测并执行策略
	// await execute(out);

	// 提取策略资金
	let to = "0xF9758dB6571Cfe61e6eB9146D82A0f0FF7ACBc45";
	await withdraw(out);

	// await positions(out);
	//swap
	// await swap(out);

	//space
	// await spacing(out);

	//mint
	// await mint(out);

	//decreaseLiquidity
	// await decreaseLiquidity(out);

	// await burn(out);
}

async function getPrice(out) {

	let tokenA = "0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984";//0xc778417E063141139Fce010982780140Aa0cD5Ab
	let tokenB = "0xc778417E063141139Fce010982780140Aa0cD5Ab";//0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984
	let token0;
	let token1;
	if(tokenA-tokenB>0){
		token0=tokenA;
		token1=tokenB
	}else{
		token0=tokenB;
		token1=tokenA;
	}
	const price = await out.getPrice(token0, token1, 3000);
	console.log("价格", price);


}

async function create(out) {
	// 创建策略
	let tokenA = "0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984";//0xc778417E063141139Fce010982780140Aa0cD5Ab
	let tokenB = "0xc778417E063141139Fce010982780140Aa0cD5Ab";//0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984
	let fee = 3000;
	let amount = new bigNumber(0.5).times(1e18);
	let to = "0xF9758dB6571Cfe61e6eB9146D82A0f0FF7ACBc45";
	let ticks = [60, 240, 480];
	let a = await out.create(tokenA, tokenB, fee, amount, to, ticks);
	// console.log(ticks[0]);
	console.log("创建策略：", a);
}

async function getStrategy(out, strategyId) {
	// 策略信息
	let a = await out.getStrategy(strategyId);
	console.log("策略归属：", a[0]);
	console.log("策略A币:", a[1]);
	console.log("策略B币：", a[2]);
	console.log("策略费率：", a[3]);
	console.log("初始投入：", a[4]);
	console.log("交换A量：", a[5]);
	console.log("交换B量：", a[6]);
	console.log("Ticks", a[7]);
	console.log("TICK数量：", a[8]);
}

async function getUserInfo(out) {
	// 所有策略ID
	let a = [];
	a = await out.getUserInfo("0xF9758dB6571Cfe61e6eB9146D82A0f0FF7ACBc45");
	console.log("所有策略id：", a.toString());

}

async function getStrategyInfo(out, strategyId) {
	// 每个策略的具体挂单信息(tick详细信息)
	let b = [];
	b = await out.getStrategyInfo(strategyId);
	console.log("tick信息:", b.toString());
}

async function getAllStrategy(out, ids) {
	let a = [];
	a = await out.getAllStrategy(ids);
	console.log("返回用户自己的所有策略信息:", a)
}

async function execute(out) {
	console.log("检测策略并执行已经满足条件的策略：", await out.execute(0))
}

async function withdraw(out) {
	let ids = [0];
	console.log("提取策略资金：", await out.withdraw(ids, "0xF9758dB6571Cfe61e6eB9146D82A0f0FF7ACBc45"));
}

async function swap(out) {
	let tokenIn = "0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984";
	let tokenOut = "0xc778417E063141139Fce010982780140Aa0cD5Ab";
	let fee = 3000;
	let to = "0xF9758dB6571Cfe61e6eB9146D82A0f0FF7ACBc45";
	let amountIn = new bigNumber(0.1).times(1e18);
	const amountOut = await out.swap(tokenIn, tokenOut, fee, to, amountIn);
	console.log(amountOut);
}

async function spacing(out){
	const space = await out.tickSpacing("0x0a8F66bb95844ff4024610135aa57E010788A1AC");
	console.log(space);
}

function _floor(tick){
	const compressed = tick / 60;
	if (tick < 0 && tick % 60 != 0) compressed--;
	return compressed * 60;
}
function _ceil(tick){
	return _floor(tick)+60;
}

async function mint(out) {
	let amountIn = new bigNumber(0.1).times(1e18);
	const res = await out.mint({
		token0: "0xA6Cc591f2Fd8784DD789De34Ae7307d223Ca3dDc",
		token1: "0xc778417E063141139Fce010982780140Aa0cD5Ab",
		fee: 3000,
		tickLower: _floor(211740),
		tickUpper: _ceil(211740),
		amount0Desired: 10000000,
		amount1Desired: 0,
		amount0Min: 30000,
		amount1Min: 0,
		recipient: "0xfAa981C4C25E1d73A3203BA842E90135DA7D33BF",
		deadline: DateNow + 3000
	});
	console.log(res);
}

async function decreaseLiquidity(out){
	// let lq = new bigNumber(138).times(1e18);
	const res = await out.decreaseLiquidity({
		tokenId:2207,
		liquidity:1000000000,
		amount0Min:0,
		amount1Min:0,
		deadline:DateNow+300
	});

	console.log(res);
}

async function getTick(out){
	console.log(await out.getTick(0,1));
}

async function positions(out){
	let p = await out.positions(2201);
	console.log(p[0].toString());
	console.log(p[1]);
	console.log(p[2]);
	console.log(p[3]);
	console.log(p[4].toString());
	console.log(p[5].toString());
	console.log(p[6].toString());
	console.log(p[7].toString());
	console.log(p[8].toString());
	console.log(p[9].toString());
	console.log(p[10].toString());
	console.log(p[11].toString());
}

async function getAB(out){
	let a = await out.a();
	let b = await out.b();
	console.log(a.toString());
	console.log("===========");
	console.log(b.toString());
}

async function burn(out){
	const b = await out.burn(2210);
	console.log(b);
}