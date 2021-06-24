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

2、网格交易数据计算的问题

3、合约如何记录用户在合约中的钱和uniswap中做range order的钱


## 网格交易逻辑讲解

我们以ETH-USDT交易对来举例，如果现在ETH价格在1923USDT，用户设置的参数为等差网格，上下区间为 1900～2000，网格数为10，投入资金为10000USDT

那么首先计算出1900～2000区间内需要进行交易的点位

我们把网格的不同参数初始化一个变量

当前价格 current_price = 1923
区间底部








