pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./interfaces/IUniswapV3Pool.sol";
import "hardhat/console.sol";

    /**
     * Network: Kovan
     * Aggregator: ETH/USD
     * Address: 0x9326BFA02ADD2366b30bacB125260Af641031331
     */
contract PriceConsumerV3 {

    AggregatorV3Interface internal priceFeed;
    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
    }
    function getLatestPrice() public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }

    // 检测uniswap oracle 与 chainlink oracle 之间的价格差距，若差距较大
    // 则移除包含这个币种的策略的流动性

    function getUniswapV3Price(uint32[] calldata secondsAgos,address pool) public view returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s){
        (tickCumulatives,secondsPerLiquidityCumulativeX128s) = IUniswapV3Pool(pool).observe(secondsAgos);
    }
}