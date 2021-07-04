// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@uniswap/v3-core/contracts/libraries/SafeCast.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "./libraries/PoolAddress.sol";
import "./interfaces/INonfungiblePositionManager.sol";
import "./interfaces/IOut.sol";
import "./interfaces/ISwapRouter.sol";
import "./interfaces/IQuoter.sol";
import "./libraries/TransferHelper.sol";

contract Out is IOut, ISwapRouter, INonfungiblePositionManager {
    // address SWAP_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    // address QUOTER_ROUTER = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;
    // address FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    // address NonfungiblePositionManager =
    //     0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
    address public SWAP_ROUTER;
    address public QUOTER_ROUTER;
    address public factory;
    address public NonfungiblePositionManager;

    constructor(
        address V3Swap_Router,
        address V3Quoter_Router,
        address V3Factory,
        address V3NFPositionManager
    ) {
        SWAP_ROUTER = V3Swap_Router;
        QUOTER_ROUTER = V3Quoter_Router;
        factory = V3Factory;
        NonfungiblePositionManager = V3NFPositionManager;
    }

    mapping(address => User) userInfo;
    mapping(uint256 => Strategy) strategy;
    mapping(uint256 => mapping(uint256 => TickSingle)) tickSingle;
    uint256 id;

    event swapEvent(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        address to,
        uint256 amountIn,
        uint256 amountOut
    );

    function create(
        address tokenA,
        address tokenB,
        uint24 fee,
        uint256 amount,
        address to,
        int24[] memory tick
    ) external payable override {
        TransferHelper.safeTransferFrom(tokenA, to, address(this), amount);
        (uint256 amountIn, uint256 amountOut) = initial(
            Strategy({
                to: to,
                tokenA: tokenA,
                tokenB: tokenB,
                fee: fee,
                amount: amount,
                amountA: 0,
                amountB: 0,
                ticks: tick,
                tickCount: tick.length
            })
        );
        strategy[id] = Strategy({
            to: to,
            tokenA: tokenA,
            tokenB: tokenB,
            fee: fee,
            amount: amount,
            amountA: amountIn,
            amountB: amountOut,
            ticks: tick,
            tickCount: tick.length
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
        address poolAddr = getPoolAddress(stg.tokenA, stg.tokenB, stg.fee);
        uint256 dividedInvest = stg.amount / stg.tickCount;
        int24 currentTick;
        (, currentTick, , , , , ) = getPoolSlot(poolAddr);
        uint256 tickL = getTick(stg.ticks, currentTick);
        if (tickL > 0) {
            amountOut = lessTick(stg, poolAddr, dividedInvest * tickL, tickL);
        }

        if (tickL < stg.tickCount - 1) {
            amountA = greatTick(
                stg,
                poolAddr,
                stg.amount - (dividedInvest * tickL),
                tickL
            );
        }
    }

    function greatTick(
        Strategy memory stg,
        address poolAddr,
        uint256 amountIn,
        uint256 tickL
    ) private returns (uint256 amountA) {
        uint256 dividedInvest = amountIn / (stg.tickCount - tickL - 1);
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0;
        uint256 amount1;
        for (uint256 i = tickL + 1; i < stg.tickCount; i++) {
            (tokenId, liquidity, amount0, amount1) = mint(
                MintParams({
                    token0: stg.tokenA,
                    token1: stg.tokenB,
                    fee: stg.fee,
                    tickLower: _floor(stg.ticks[i], poolAddr),
                    tickUpper: _ceil(stg.ticks[i], poolAddr),
                    amount0Desired: dividedInvest,
                    amount1Desired: 0,
                    amount0Min: 0,
                    amount1Min: 0,
                    recipient: address(this),
                    deadline: block.timestamp + 300
                })
            );
            tickSingle[id][i] = TickSingle({
                tokenId: tokenId,
                tick: stg.ticks[i],
                token: stg.tokenA,
                amount: amount0,
                liquidity: liquidity
            });
            amountA += amount0;
        }
    }

    function lessTick(
        Strategy memory stg,
        address poolAddr,
        uint256 amountIn,
        uint256 tickL
    ) private returns (uint256 amountOut) {
        uint256 dividedInvest = amountIn / tickL;
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0;
        uint256 amount1;
        for (int256 j = int256(tickL) - 1; j >= 0; j--) {
            amount1 = swap(
                stg.tokenA,
                stg.tokenB,
                stg.fee,
                address(this),
                dividedInvest
            );
            (tokenId, liquidity, amount0, amount1) = mint(
                MintParams({
                    token0: stg.tokenA,
                    token1: stg.tokenB,
                    fee: stg.fee,
                    tickLower: _floor(stg.ticks[uint256(j)], poolAddr),
                    tickUpper: _ceil(stg.ticks[uint256(j)], poolAddr),
                    amount0Desired: 0,
                    amount1Desired: amount1,
                    amount0Min: 0,
                    amount1Min: 3000,
                    recipient: address(this),
                    deadline: block.timestamp + 3000
                })
            );
            tickSingle[id][uint256(j) + 1] = TickSingle({
                tokenId: tokenId,
                tick: stg.ticks[uint256(j)],
                token: stg.tokenB,
                amount: amount1,
                liquidity: liquidity
            });
            amountOut += amount1;
        }
    }

    function getTick(int24[] memory tick, int24 currentTick)
        internal
        pure
        returns (uint256)
    {
        uint256 i;
        for (i; i < tick.length; i++) {
            if (currentTick - tick[i] <= 0) {
                return i;
            }
        }
        return i;
    }

    function withdraw(uint256[] memory ids, address to) external payable override {
        uint256 amountA;
        uint256 amountB;
        address token = strategy[ids[0]].tokenA;
        // 一次查询每一个策略 id
        for (uint256 index; index < ids.length; index++) {
            Strategy storage stg = strategy[ids[index]];

            for (uint256 j = 1; j <= stg.tickCount; j++) {
                // 查询每一个 tick 信息
                TickSingle storage tickInfo = tickSingle[ids[index]][j];
                if (tickInfo.liquidity != 0) {
                    // 移除当前 tick，去上一个 tick 添加
                    (uint256 amount0, uint256 amount1) = decreaseLiquidity(
                        DecreaseLiquidityParams({
                            tokenId: tickInfo.tokenId,
                            liquidity: tickInfo.liquidity,
                            amount0Min: 0,
                            amount1Min: 0,
                            deadline: block.timestamp + 200
                        })
                    );

                    tickInfo.liquidity = 0;
                    tickInfo.amount = 0;

                    amountA += amount0;
                    amountB += amount1;
                }
            }
            if (amountB != 0) {
                amountA += swap(
                    stg.tokenB,
                    stg.tokenA,
                    stg.fee,
                    address(this),
                    amountB
                );
            }
            amountB = 0;
            stg.amount = 0;
            stg.amountA = 0;
            stg.amountB = 0;
        }
        TransferHelper.safeTransfer(token, to, amountA);
    }

    function swap(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        address to,
        uint256 amountIn
    ) public payable returns (uint256) {
        TransferHelper.safeApprove(tokenIn, SWAP_ROUTER, type(uint256).max);
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
        emit swapEvent(tokenIn, tokenOut, fee, to, amountIn, amountOut);
        return amountOut;
    }

    // 检测驱动执行移除流动性
    function execute(uint256 ids) external payable override {
        // 获取用户设置的策略
        Strategy storage strategyInfo = strategy[ids];
        address poolAddr = getPoolAddress(
            strategyInfo.tokenA,
            strategyInfo.tokenB,
            strategyInfo.fee
        );
        // 获取池子 TICK
        (, int24 poolTick, , , , , ) = IUniswapV3Pool(poolAddr).slot0();

        // 找到用户设置的每一个 tick 做判断
        for (uint256 i; i < strategyInfo.tickCount; i++) {
            TickSingle storage tickInfo = tickSingle[ids][i + 1];

            // 判断tick是否越界，越界则移除，否则不管
            if (tickInfo.tick < poolTick) {
                if (tickInfo.token != strategyInfo.tokenB) {
                    // 移除当前 tick，去上一个 tick 添加
                    (uint256 amount0, uint256 amount1) = decreaseLiquidity(
                        DecreaseLiquidityParams({
                            tokenId: tickInfo.tokenId,
                            liquidity: tickInfo.liquidity,
                            amount0Min: 0,
                            amount1Min: 0,
                            deadline: block.timestamp + 200
                        })
                    );

                    // 更新策略币量
                    strategyInfo.amountA -= tickInfo.amount;
                    strategyInfo.amountB += amount1;
                    // 更新本次 tick 信息
                    tickSingle[ids][i] = TickSingle({
                        tokenId: tickInfo.tokenId,
                        tick: tickInfo.tick,
                        token: tickInfo.token,
                        amount: 0,
                        liquidity: 0
                    });

                    // 用户设置的上一个 tick 添加单币流动性,并更新其 tick 信息
                    lastTickMint(ids, i - 1, poolAddr, amount0, amount1);
                }
            } else {
                if (tickInfo.token != strategyInfo.tokenA) {
                    // 当池子的 tick 小于用户的记录的 tick: 移除当前 tick 后去下一个 tick 添加流动性
                    (uint256 amount0, uint256 amount1) = decreaseLiquidity(
                        DecreaseLiquidityParams({
                            tokenId: tickInfo.tokenId,
                            liquidity: tickInfo.liquidity,
                            amount0Min: 0,
                            amount1Min: 0,
                            deadline: block.timestamp + 200
                        })
                    );

                    // 更新策略币量
                    strategyInfo.amountA += amount0;
                    strategyInfo.amountB -= tickInfo.amount;

                    // 更新本次移除的 tick 信息
                    tickSingle[ids][i] = TickSingle({
                        tokenId: tickInfo.tokenId,
                        tick: tickInfo.tick,
                        token: tickInfo.token,
                        amount: 0,
                        liquidity: 0
                    });

                    // 下一个tick添加流动性
                    // 用户设置的上一个 tick 添加单币流动性,并更新其 tick 信息
                    lastTickMint(ids, i + 1, poolAddr, amount0, amount1);
                }
            }
        }
    }

    // 上一个tick挂买单：既到上一个tick添加流动性
    function lastTickMint(
        uint256 ids,
        uint256 tickID,
        address poolAddr,
        uint256 amount0,
        uint256 amount1
    ) internal {
        // 获取用户设置的tick
        Strategy storage strategyInfo = strategy[ids];
        TickSingle storage tickInfo = tickSingle[ids][tickID];
        // 添加流动性
        (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amountA,
            uint256 amountB
        ) = mint(
            MintParams({
                token0: strategyInfo.tokenA,
                token1: strategyInfo.tokenB,
                fee: strategyInfo.fee,
                tickLower: _floor(tickInfo.tick, poolAddr),
                tickUpper: _ceil(tickInfo.tick, poolAddr),
                amount0Desired: amount0,
                amount1Desired: amount1,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp + 200
            })
        );
        // 更新tick信息
        if (amountA == 0) {
            tickInfo.tokenId = tokenId;
            tickInfo.liquidity = liquidity;
            tickInfo.token = strategyInfo.tokenB;
            tickInfo.amount = amountB;
            // // 更新策略币的量
            // strategyInfo.amountA -= amountA;
            // strategyInfo.amountB -= amountB;
        } else {
            tickInfo.tokenId = tokenId;
            tickInfo.liquidity = liquidity;
            tickInfo.token = strategyInfo.tokenA;
            tickInfo.amount = amountA;
            // // 更新策略币的量
            // strategyInfo.amountA -= amountA;
            // strategyInfo.amountB -= amountB;
        }
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
        for (uint32 j = 1; j <= strategyInfos.tickCount; j++) {
            tickINfo[j - 1] = tickSingle[strategyId][j];
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

    // 获取tick下限
    function _floor(int24 tick, address pool) internal view returns (int24) {
        int24 compressed = tick / tickSpacing(pool);
        if (tick < 0 && tick % tickSpacing(pool) != 0) compressed--;
        return compressed * tickSpacing(pool);
    }

    // 获取tick上限
    function _ceil(int24 tick, address pool) internal view returns (int24) {
        int24 floor = _floor(tick, pool);
        return floor + tickSpacing(pool);
    }

    function getTick(uint256 ids, uint256 i)
        external
        view
        returns (TickSingle memory)
    {
        return tickSingle[ids][i];
    }

    function getPoolAddress(
        address tokenA,
        address tokenB,
        uint24 fee
    ) public view returns (address) {
        return
            PoolAddress.computeAddress(
                factory,
                PoolAddress.getPoolKey(tokenA, tokenB, fee)
            );
    }

    // 获取池子的当前相关信息
    function getPoolSlot(address pool)
        public
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        )
    {
        return IUniswapV3Pool(pool).slot0();
    }

    function tickBitmap(int16 wordPosition, address pool)
        external
        view
        returns (uint256)
    {
        return IUniswapV3Pool(pool).tickBitmap(wordPosition);
    }

    function ticks(int24 tick, address pool)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        )
    {
        return IUniswapV3Pool(pool).ticks(tick);
    }

    function tickSpacing(address pool) public view returns (int24) {
        return IUniswapV3Pool(pool).tickSpacing();
    }

    // 通过 tokenId 获取 NFT 的相关信息
    function positions(uint256 tokenId)
        external
        view
        override
        returns (
            uint96 nonce,
            address operator,
            address tokenA,
            address tokenB,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        )
    {
        return
            INonfungiblePositionManager(NonfungiblePositionManager).positions(
                tokenId
            );
    }

    // 第一次添加流动性的时候将返回 NFT (在同一个 tick 范围上只会返回一个 NFT)
    function mint(MintParams memory params)
        public
        payable
        override
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        TransferHelper.safeApprove(
            params.token1,
            NonfungiblePositionManager,
            type(uint256).max
        );
        TransferHelper.safeApprove(
            params.token0,
            NonfungiblePositionManager,
            type(uint256).max
        );
        (tokenId, liquidity, amount0, amount1) = INonfungiblePositionManager(
            NonfungiblePositionManager
        ).mint(params);
    }

    // 在该 tick 范围中非第一次添加流动性时调用
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        override
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        (liquidity, amount0, amount1) = INonfungiblePositionManager(
            NonfungiblePositionManager
        ).increaseLiquidity(params);
    }

    // 移除流动性
    function decreaseLiquidity(DecreaseLiquidityParams memory params)
        public
        payable
        override
        returns (uint256 amount0, uint256 amount1)
    {
        (uint256 amA, uint256 amB) = INonfungiblePositionManager(
            NonfungiblePositionManager
        ).decreaseLiquidity(params);

        (amount0, amount1) = collect(
            CollectParams({
                tokenId: params.tokenId,
                recipient: address(this),
                amount0Max: uint128(amA),
                amount1Max: uint128(amB)
            })
        );
    }

    function collect(CollectParams memory params)
        public
        payable
        override
        returns (uint256 amount0, uint256 amount1)
    {
        (amount0, amount1) = INonfungiblePositionManager(
            NonfungiblePositionManager
        ).collect(params);
    }

    // 移除流动性
    function burn(uint256 tokenId) external payable override {}
}
