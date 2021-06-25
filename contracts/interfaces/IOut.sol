// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
pragma abicoder v2;

interface IOut {

	// 用户信息结构体
	struct User{
		address token;	//投入币种
		address tokenA;	//转换后币种A
		address tokenB;	//转换后币种B
		uint256 amount;	//初始投入量
		uint256 amountA;	//转换后tokenA的量
		uint256 amountB;	//转换后tokenB的量
		uint256 liquidity;	//添加流动性后返回lptoken的量
	}

	// 策略方案结构体
	struct Strategy{
		address tokenA;	//流动性挖矿tokenA
		address tokenB;	//流动性挖矿tokenB
		uint256 amountA;	//tokenA的量
		uint256 amountB;	//tokenB的量
		uint256 minTick;	//最下tick
		uint256 maxTick;	//最大tick
	}

	// // 用户地址对应用户信息
	// mapping(address => User) userInfo;
	// // 池子地址对应策略信息
	// mapping(address => Strategy) strategy;
	
	/**
	 * @dev 用户投入单币资金
	 * @param tokenA 抵押的币种(默认就是USDT)
	 * @param tokenB 要匹配的tokenB
	 * @param amount 抵押的USDT量
	 * @param to lp用户地址
	 * @return liquidity 返回lptoken的量
	 */
	function deposit(address tokenA,address tokenB,uint256 amount,address to) external payable returns(uint256 liquidity);

	/**
	 * @dev 用户提取资金
	 * @param liquidity 提取流动性的量
	 * @param to lp用户地址
	 * @return amount 提取tokenB的量
	 */
	function withdraw(uint256 liquidity,address to) external payable returns(uint256 amount);

	/**
	 * @dev 设置策略方案
	 * @param tokenA 币种A
	 * @param tokenB 币种B
	 * @param amountA 调动tokenA的量
	 * @param amountB 调动tokenB的量
	 * @param minTick 最小tick
	 * @param maxTick 最大tick
	 */
	function setStrategy(address tokenA,address tokenB,uint256 amountA,uint256 amountB,uint256 minTick,uint256 maxTick) external;

	/**
	 * @dev 获取策略
	 * @return 返回策略信息
	 */
	function getStrategy() external view returns(Strategy memory);

	/**
	 * @dev 套利者执行方法
	 */
	function execute() external payable;

	/**
	 * @dev 用户信息查询方法
	 * @param to lp用户地址
	 * @return User 用户信息
	 */
	function getUserInfo(address to) external view returns(User memory);
}
