//+------------------------------------------------------------------+
//|                                            1009ScalpFractals.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
#include <Original\MyUtils.mqh>
#include <Original\MyTrade.mqh>
#include <Original\MyCalculate.mqh>
#include <Original\MyTest.mqh>
#include <Original\MyPrice.mqh>
#include <Original\MyPosition.mqh>
#include <Original\MyOrder.mqh>
#include <Indicators\TimeSeries.mqh>
#include <Indicators\Oscilators.mqh>
#include <Indicators\Trend.mqh>
#include <Trade\OrderInfo.mqh>
#include <Arrays\ArrayDouble.mqh>
#include <Indicators\BillWilliams.mqh>
CTrade trade;
CiMA ciMAShort, ciMALong;
CiBands ciBands;
CiStochastic ciStochastic;
#include <Generic\Interfaces\IComparable.mqh>

input int TPCoef, SLCoef;
input ENUM_TIMEFRAMES Timeframe;
bool tradable = false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyTrade myTrade();
MyPrice myPrice(PERIOD_M5, 3);

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   MyUtils myutils(60 * 27);
   myutils.Init();

   ciBands.Create(_Symbol, Timeframe, 20, 0, 2, PRICE_CLOSE);
   ciStochastic.Create(_Symbol, Timeframe, 5, 3, 3, MODE_SMA, STO_LOWHIGH);

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   myPosition.Refresh();
   myTrade.Refresh();
   myPrice.Refresh();
   ciBands.Refresh();
   ciStochastic.Refresh();

   myTrade.CheckSpread();
   myPosition.Trailings(POSITION_TYPE_BUY,ciBands.Base(0));
   myPosition.Trailings(POSITION_TYPE_SELL,ciBands.Base(0));
   
   MyOrder myOrder;
   myOrder.Refresh();
   if(myOrder.wasOrderedInTheSameBar(Timeframe)) myTrade.istradable = false;

   if(ciStochastic.Main(2) > 80 && ciStochastic.Main(1) <= 80 ) myPosition.CloseAllPositions(POSITION_TYPE_BUY);
   if(ciStochastic.Main(2) < 20 && ciStochastic.Main(1) >= 20 ) myPosition.CloseAllPositions(POSITION_TYPE_SELL);


   if(!myTrade.istradable || !tradable) return;

   if(ciBands.Upper(2) < myPrice.getData(2).high && ciBands.Upper(1) < myPrice.getData(1).high) {
      if(myPrice.RosokuIsPlus(2) && myPrice.RosokuIsPlus(1))
         myTrade.signal = "buy";
   }
   if(ciBands.Lower(2) > myPrice.getData(2).low && ciBands.Lower(1) > myPrice.getData(1).low) {
      if(!myPrice.RosokuIsPlus(2) && !myPrice.RosokuIsPlus(1))
         myTrade.signal = "sell";
   }

   double PriceUnit = 10 * _Point;
   if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions / 2 && myTrade.signal == "buy") {
      if(myTrade.isInvalidTrade(ciBands.Base(0), myTrade.Ask + PriceUnit  * TPCoef)) return;
      trade.Buy(myTrade.lot, NULL, myTrade.Ask, ciBands.Base(0), myTrade.Ask + PriceUnit  * TPCoef, NULL);
   }

   if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions / 2 && myTrade.signal == "sell") {
      if(myTrade.isInvalidTrade(ciBands.Base(0), myTrade.Bid - PriceUnit * TPCoef)) return;
      trade.Sell(myTrade.lot, NULL, myTrade.Bid, ciBands.Base(0), myTrade.Bid - PriceUnit * TPCoef, NULL);
   }


}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer() {
   myPosition.Refresh();
   myTrade.Refresh();

   tradable = true;

   myTrade.CheckFridayEnd();
   myTrade.CheckYearsEnd();
   myTrade.CheckBalance();
   myTrade.CheckMarginLevel();

   if(!myTrade.istradable) {
      myPosition.CloseAllPositions(POSITION_TYPE_BUY);
      myPosition.CloseAllPositions(POSITION_TYPE_SELL);
      tradable = false;
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
double OnTester() {
   MyTest myTest;
   double result =  myTest.min_dd_and_mathsqrt_profit_trades_only_longs();
   return  result;
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
