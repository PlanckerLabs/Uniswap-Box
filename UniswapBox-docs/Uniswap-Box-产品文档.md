## Uniswap-Box 一个基于Uniswap的网格交易工具

![Product structure](https://github.com/PlanckerLabs/PictureRepo/blob/main/Uniswap%20Box%20Product%20Structure.png)

原型图链接：https://w5jtz1.axshare.com

产品主要为用户提供了基于uniswap的网格交易工具，可以使用户在Uniswap上更方便的进行交易。

### 产品主要分为四个部分

1、前端页面

2、后端合约，实现调用Uniswap交易功能

3、网格交易脚本，调用合约进行网格交易

4、数据获取，主要需要实时获取Uniswap价格。

### 本次Hackathon需要实现的模型如原型图所示，可暂缓实现部分如下

1、流动性图，k线图

2、交易记录

3、网格工具只保留等差网格


问题

1、gas费问题，触发合约者可能无法支付gas
用户如何支付gas

2、网格交易数据计算的问题

3、合约如何记录用户在合约中的钱和uniswap中做range order的钱


## 网格交易逻辑讲解

首先理解什么是网格交易，花两分钟过一下这个视频即可 https://www.bilibili.com/video/BV187411V7mU?from=search&seid=9966052669478390140

### 接下来说网格交易技术实现方面的具体细节

#### 1、从用户填入参数到挂单

我们以ETH-USDT交易对来举例，如果现在ETH价格在1923USDT，用户设置的参数为等差网格，上下区间为 1900～2000，网格数为5，投入资金为10000USDT

那么首先计算出1900～2000区间内需要进行交易的点位

我们把网格的不同参数初始化一个变量

当前价格 current_price = 1923
区间底部 bottom_price = 1900
区间顶部 top_price = 2000
投资金额（单位USDT）invest_amount = 10000
网格数量 grid_number = 5

需要交易的点位计算方法

range_amount =  (top_price - bottom_price)/(grid_number - 1)

也就是从1900开始，每隔一个range_amount 就是一个交易点位，这里存在无法整除的情况，需要四舍五入保留两位小数。

所以发生交易的点位是1900、1925、1950、1975、2000 五个点位

现在价格为 1923，判断与1923最近的点位是哪个，判断后，最近的点位是 1925，这个点位暂不挂单，原因是如果挂单被吃到，那么利润额不符合一个网格25刀利润额的要求

然后把 invest_amount 分成5份，

divided_invest_amount = invest_amount/5

卖出其中4份USDT换成ETH，判断大于current_price，除1925这个价格的的三个位置挂卖单，卖单金额为 divided_invest_amount * 4/3

一份USDT在1900挂买单

#### 2、行情波动，开始网格交易

用户账户USDT的数量 USDT_amount 
用户账户ETH的数量  ETH_amount
现在挂的买单数量 buy_order_amount
现在挂的卖单数量 sell_order_amount


我们以ETH上涨为例，若行情上涨至1950，则1950的卖单被吃，在被吃的同时，需要在1925挂上买单，挂单金额为1950点位eth卖出的USDT数量，若继续上涨至1975，则1975的卖单被吃，同时在1950的位置挂上买单，若行情上涨突破2000，则2000卖单被吃的同时，在1975的位置挂入买单。若ETH不下跌至2000以下，则网格交易暂时不会触发。若回到1975，则买单被吃，与此同时在2000的位置挂入卖单。

每笔交易的交易手续费由用户自行支付



ETH下跌同理。只是挂单金额计算公式为ETH_amount/(sell_order_amount + 1)

#### 3、停止网格

用户点击停止按钮，网格交易将会自动终止，pending中的交易将被取消，当没有pending交易时，网格交易即可完成停止的过程。




























