// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./interfaces/IOut.sol";
import "./interfaces/ISwapRouter.sol";
import "./interfaces/IQuoter.sol";
import "./libraries/TransferHelper.sol";

contract Out is IOut, ISwapRouter {
    address SWAP_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address QUOTER_ROUTER = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;

    mapping(address => User) userInfo;
    mapping(uint256 => Strategy) strategy;
    mapping(uint256 => mapping(uint32 => TickSingle)) tickSingle;
    uint256 id;

    function create(
        address tokenA,
        address tokenB,
        uint24 fee,
        uint256 amount,
        address to,
        uint256 tickMin,
        uint256 tickMax,
        uint32 tickCount
    ) external payable override {
		TransferHelper.safeTransferFrom(tokenA, to, address(this), amount);
		TransferHelper.safeApprove(tokenA, SWAP_ROUTER, type(uint256).max);
		TransferHelper.safeApprove(tokenA, QUOTER_ROUTER, type(uint256).max);
        uint256 interval = (tickMax - tickMin) / (tickCount - 1);
        uint256 min = tickMin;
        for (uint32 i = 1; i <= tickCount; i++) {
            tickSingle[id][i] = TickSingle({
                tickId: i,
                tickPrice: min,
                token: tokenA,
                amount: 0
            });
            min += interval;
        }
        strategy[id] = Strategy({
            tokenA: tokenA,
            tokenB: tokenB,
            fee: fee,
            amount: amount,
            amountA: 0,
            amountB: 0,
            minTick: tickMin,
            maxTick: tickMax,
            tickCount: tickCount
        });

        User storage user = userInfo[to];
        user.strategyIds.push(id);
        id++;
    }

    function withdraw(uint256[] memory ids, address to)
        external
        payable
        override
    {
        uint256 amount;
        for (uint256 index; index < ids.length; index++) {
            Strategy storage stg = strategy[ids[index]];
            amount += stg.amountA;
            amount += swap(
                stg.tokenB,
                stg.tokenA,
                stg.fee,
                address(this),
                stg.amountB
            );
        }
        TransferHelper.safeTransfer(strategy[ids[0]].tokenA, to, amount);
    }

    function swap(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        address to,
        uint256 amountIn
    ) public payable returns (uint256) {
        uint256 amountOut = ISwapRouter(SWAP_ROUTER).exactInputSingle(
            ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: fee,
                recipient: to,
                deadline: block.timestamp + 300,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            })
        );
        return amountOut;
    }
	function execute() external payable override {
		
		// 获取用户策略信息
		for(uint256 i = id; i > 0; i--) {
			Strategy memory strategyInfo = getStrategy(i);
			// 获取当前价格
			uint256 price = getPrice(strategyInfo.tokenA,strategyInfo.tokenB,strategyInfo.fee);
			if(strategyInfo.amount !=0) {
				uint32 count = strategyInfo.tickCount;
				uint256 minTick = strategyInfo.minTick;
				uint256 maxTick = strategyInfo.maxTick;
				(uint256 tickPosId) = equalDifferenceStrategy(minTick, maxTick,price, count);
				if(tickPosId == 0) {
					// 获取总金额
					uint256 amountOut = swap(strategyInfo.tokenA,strategyInfo.tokenB,strategyInfo.fee, address(this),strategyInfo.amount);
					// 更新策略信息

				}else {
					uint256 sellTickNum = strategyInfo.tickCount - tickPosId;
					uint256 equalDifference = (strategyInfo.maxTick - strategyInfo.minTick) / count;
					// 买入的量
					uint256 buy = strategyInfo.amount * (tickPosId - 1) / strategyInfo.tickCount;
					// 每个 tick 卖出的量
					uint256 sell = (strategyInfo.amount * sellTickNum / strategyInfo.tickCount) / sellTickNum;
					
					uint256 amountOut = swap(strategyInfo.tokenA, strategyInfo.tokenB, strategyInfo.fee, address(this), strategyInfo.amount);


				}
			}

		}

		// 判断策略设置的条件是否满足

		// 满足条件既被执行

		// 更新被执行的策略

	}

	// 计算等差网格策略
	function equalDifferenceStrategy(uint256 min, uint256 max,uint256 price, uint32 count) internal pure returns(uint256 tickPosId) {
		uint256 equalDifference = (max - min) / count; // 200 5
		if(price < min) {
			tickPosId = 0;
		}else {
			uint256 priceSub = price - min;
			for(uint32 tick = 1; tick <= count; tick++) {
				if(priceSub < equalDifference) {
					tickPosId = tick + 1;
					break;
				}else{
					priceSub = priceSub - equalDifference;
				}
				
			}
		}
		
		// return equalDifference;
	}

	// 判断是否处于其中一个 tick 中,是则返回处于的 tickCount
	// function getTickPosition(uint256 strategyId) public view returns(uint32){
	// 	// 获取当前价格
	// 	uint256 price = getPrice();
	// }

	function getStrategy(uint256 strategyId) public view override returns (Strategy memory) {
		// 返回一个策略信息
		Strategy memory strategyInfo = strategy[strategyId];
		return strategyInfo;
	}

	function getUserInfo(address to)
		external
		view
		override
		returns (uint256[] memory)
	{	
		// 返回一个用户对应的所有策略
		User memory user = userInfo[to];
		return user.strategyIds;
	}

	function getTickSingle(uint32 tickId) public view returns(TickSingle memory) {
		TickSingle memory tickInfo = tickSingle[0][tickId];
		return tickInfo;
	}

    function getPrice(
        address tokenIn,
        address tokenOut,
        uint24 fee
    ) public returns (uint256) {
        return
            IQuoter(QUOTER_ROUTER).quoteExactInputSingle(
                tokenIn,
                tokenOut,
                fee,
                1e18,
                0
            );
    }

    function exactOutput(ExactOutputParams calldata params)
        external
        payable
        override
        returns (uint256 amountIn)
    {}

    function exactOutputSingle(ExactOutputSingleParams calldata params)
        external
        payable
        override
        returns (uint256 amountIn)
    {}

    function exactInput(ExactInputParams calldata params)
        external
        payable
        override
        returns (uint256 amountOut)
    {}

    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        override
        returns (uint256 amountOut)
    {}

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external override {}
}
