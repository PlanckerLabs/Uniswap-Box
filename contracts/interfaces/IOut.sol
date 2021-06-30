// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
pragma abicoder v2;

interface IOut {
	// 用户信息结构体
	struct User {
		uint256[] strategyIds;
	}

	// 策略方案结构体
	struct Strategy {
		address to;
		address tokenA;		//投入币种A
		address tokenB;		//交换币种B
		uint24 fee;			//费率(分别为500,3000,10000)
		uint256 amount;		//初始投入量
		uint256 amountA;	//转换后tokenA的量
		uint256 amountB;	//转换后tokenB的量
		uint256 minTick;	//最下tick
		uint256 maxTick;	//最大tick
		uint32 tickCount;
	}

	struct TickSingle{
		uint32 tickId;
		uint256 tickPrice;
		address token;
		uint256 amount;
	}

	// // 用户地址对应用户信息
	// mapping(address => User) userInfo;
	// // 池子地址对应策略信息
	// mapping(uint => Strategy) strategy;
	// uint _id;
	
	/**
	 * @dev 用户投入单币资金
	 * @param tokenA 抵押的币种(默认就是USDT)
	 * @param tokenB 要匹配的tokenB
	 * @param amount 抵押的USDT量
	 * @param to lp用户地址
	 * @param tickMin 最小的Tick
	 * @param tickMax 最大的Tick
	 */
	function create(address tokenA, address tokenB,uint24 fee, uint256 amount, address to, uint256 tickMin, uint tickMax, uint32 tickCount) external payable;

	/**
	 * @dev 用户提取资金
	 * @param ids 撤回资金的id列表
	 * @param to lp用户地址
	 */
	function withdraw(uint[] memory ids, address to) external payable;

	/**
	 * @dev 获取策略
	 * @return 返回策略信息
	 */
	function getStrategy(uint256 strategyId) external view returns(Strategy memory);

	/**
	 * @dev 套利者执行方法
	 */
	function execute() external payable;

	/**
	 * @dev 用户信息查询方法
	 * @param to lp用户地址
	 * @return User 用户信息
	 */
	function getUserInfo(address to) external view returns(uint256[] memory);
}
