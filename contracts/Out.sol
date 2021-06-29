// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./interfaces/IOut.sol";
import "./interfaces/ISwapRouter.sol";
import "./interfaces/IQuoter.sol";
import "./libraries/TransferHelper.sol";

contract Out is IOut, ISwapRouter {
    // address SWAP_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    // address QUOTER_ROUTER = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;
    address public SWAP_ROUTER;
    address public QUOTER_ROUTER;

    constructor(address V3Swap_Router,address V3Quoter_Router){
        SWAP_ROUTER = V3Swap_Router;
        QUOTER_ROUTER = V3Quoter_Router;
    }

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
        (uint256 amountIn, uint256 amountOut) = initial(
            Strategy({
                tokenA: tokenA,
                tokenB: tokenB,
                fee: fee,
                amount: amount,
                amountA: 0,
                amountB: 0,
                minTick: tickMin,
                maxTick: tickMax,
                tickCount: tickCount
            })
        );
        strategy[id] = Strategy({
            tokenA: tokenA,
            tokenB: tokenB,
            fee: fee,
            amount: amount,
            amountA: amountIn,
            amountB: amountOut,
            minTick: tickMin,
            maxTick: tickMax,
            tickCount: tickCount
        });

        User storage user = userInfo[to];
        user.strategyIds.push(id);
        id++;
    }

    // 创建新的策略时，对策略进行初始操作
    function initial(Strategy memory stg)
        internal
        returns (uint256 amountA, uint256 amountOut)
    {
        uint256 range = (stg.maxTick - stg.minTick) / (stg.tickCount - 1);
        uint256 dividedInvest = stg.amount / stg.tickCount;
        uint256 currentPrice = getPrice(stg.tokenA, stg.tokenB, stg.fee);
        uint256 min = stg.minTick;
        uint32 i = 1;
        for (i; i < stg.tickCount; i++) {
            if (currentPrice < min) {
                break;
            }
            min += range;
        }

        for (uint32 j = i - 1; j >= 1; j--) {
            tickSingle[id][j] = TickSingle({
                tickId: j,
                tickPrice: stg.minTick + (range * (j - 1)),
                token: stg.tokenA,
                amount: dividedInvest
            });
            amountA += dividedInvest;
        }
        if (i < stg.tickCount) {
            uint256 amountIn = dividedInvest * (stg.tickCount - (i - 1));
            amountOut = swap(
                stg.tokenA,
                stg.tokenB,
                stg.fee,
                address(this),
                amountIn
            );
            tickSingle[id][i] = TickSingle({
                tickId: i,
                tickPrice: stg.minTick + (range * i),
                token: stg.tokenB,
                amount: 0
            });
            uint256 a = amountOut / (stg.tickCount - i);
            for (i + 1; i < stg.tickCount; i++) {
                tickSingle[id][i + 1] = TickSingle({
                    tickId: i + 1,
                    tickPrice: stg.minTick + (range * i),
                    token: stg.tokenB,
                    amount: a
                });
            }
        }
    }

    function withdraw(uint256[] memory ids, address to)
        external
        payable
        override
    {
        uint256 amount;
        address token = strategy[ids[0]].tokenA;
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
            delete strategy[ids[index]];
        }
        TransferHelper.safeTransfer(token, to, amount);
    }

    function swap(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        address to,
        uint256 amountIn
    ) public payable returns (uint256) {
        TransferHelper.safeApprove(tokenIn, SWAP_ROUTER, amountIn);
        uint256 amountOut = exactInputSingle(
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

    // 套利者执行
    function execute() external payable override {
        // 获取用户策略信息
        for (uint256 i = id; i > 0; i--) {
            Strategy memory strategyInfo = getStrategy(i);
            // 获取当前价格
            uint256 price = getPrice(
                strategyInfo.tokenA,
                strategyInfo.tokenB,
                strategyInfo.fee
            );
            // 获取 tick 对应信息
            for (uint32 ticks = 1; ticks <= strategyInfo.tickCount; ticks++) {
                TickSingle memory info = tickSingle[i][ticks];

                if (strategyInfo.tokenA != info.token) {
                    // 策略的币和挂单的币相等则为挂的单卖
                    if (price >= info.tickPrice && info.amount != 0) {
                        // B -> A
                        uint256 amountOutA = swap(
                            info.token,
                            strategyInfo.tokenA,
                            strategyInfo.fee,
                            address(this),
                            info.amount
                        );
                        // 更新本单信息：将本次的卖单卖出的量拿去前面一个 tick 挂买单
                        tickSingle[i][ticks] = TickSingle({
                            tickId: ticks,
                            tickPrice: info.tickPrice,
                            token: strategyInfo.tokenB,
                            amount: 0
                        });
                        // 上一个 tick 挂的买单信息
                        updateStrategy(i, ticks - 1, amountOutA);

                        // 更新策略中的金额
                        strategyInfo.amountA =
                            strategyInfo.amountA +
                            amountOutA;
                        strategyInfo.amountB =
                            strategyInfo.amountB -
                            info.amount;
                    }
                } else {
                    // 策略币和记录币一样则挂的买单
                    if (price <= info.tickPrice && info.amount != 0) {
                        // A -> B
                        uint256 amountOutB = swap(
                            info.token,
                            strategyInfo.tokenB,
                            strategyInfo.fee,
                            address(this),
                            info.amount
                        );
                        // 更新本单信息：将本次的买单买好后的量拿去后面一个 tick 挂卖单
                        tickSingle[i][ticks] = TickSingle({
                            tickId: ticks,
                            tickPrice: info.tickPrice,
                            token: strategyInfo.tokenA,
                            amount: 0
                        });

                        // 下一个 tick 挂的卖单信息
                        updateStrategy(i, ticks + 1, amountOutB);

                        // 更新策略中的金额
                        strategyInfo.amountA =
                            strategyInfo.amountA -
                            info.amount;
                        strategyInfo.amountB =
                            strategyInfo.amountB +
                            amountOutB;
                    }
                }
            }
        }
    }

    // 更新策略(上一个、下一个 tick 挂的买卖单信息)
    function updateStrategy(
        uint256 strategyId,
        uint32 tickId,
        uint256 amount
    ) internal {
        Strategy memory strategyInfo = getStrategy(strategyId);
        TickSingle memory info = tickSingle[strategyId][tickId];
        tickSingle[strategyId][tickId] = TickSingle({
            tickId: tickId,
            tickPrice: info.tickPrice,
            token: strategyInfo.tokenA,
            amount: amount
        });
    }

    // 1、返回一个用户对应的所有策略 id
    function getUserInfo(address to)
        external
        view
        override
        returns (uint256[] memory)
    {
        User memory user = userInfo[to];
        return user.strategyIds;
    }

    // 2、返回一个策略信息
    function getStrategy(uint256 strategyId)
        public
        view
        override
        returns (Strategy memory)
    {
        Strategy memory strategyInfo = strategy[strategyId];
        return strategyInfo;
    }

    // 3、返回用户自己的所有策略信息
    function getAllStrategy(uint256[] memory ids)
        public
        view
        returns (Strategy[] memory)
    {
        Strategy[] memory allStrategy = new Strategy[](ids.length);
        for (uint256 i; i < ids.length; i++) {
            uint256 strategyId = ids[i];
            allStrategy[i] = strategy[strategyId];
        }
        return allStrategy;
    }

    // 4、返回一个策略对应的所有 tick 的具体信息
    function getStrategyInfo(uint256 strategyId)
        public
        view
        returns (TickSingle[] memory)
    {
        Strategy memory strategyInfos = getStrategy(strategyId);
        TickSingle[] memory tickINfo = new TickSingle[](
            strategyInfos.tickCount
        );
        for (uint32 j; j <= strategyInfos.tickCount; j++) {
            tickINfo[j] = tickSingle[strategyId][j];
        }
        return tickINfo;
    }

    function getPrice(
        address tokenIn,
        address tokenOut,
        uint24 fee
    ) public returns (uint256) {
        TransferHelper.safeApprove(tokenIn, QUOTER_ROUTER, type(uint256).max);
        return
            IQuoter(QUOTER_ROUTER).quoteExactInputSingle(
                tokenIn,
                tokenOut,
                fee,
                1e18,
                0
            );
    }

    function exactInputSingle(ExactInputSingleParams memory params)
        public
        payable
        override
        returns (uint256 amountOut)
    {
        amountOut = ISwapRouter(SWAP_ROUTER).exactInputSingle(params);
    }

    // 继承自接口的方法，可不进行实现
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external override {}
}
