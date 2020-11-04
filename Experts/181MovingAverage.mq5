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
#include <Original\Oyokawa.mqh>
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
CiMA ciMALong, ciMAMiddle, ciMAShort;
CiBands ciBands;
CiMACD ciMacdLong, ciMacdShort;
CiStochastic ciStochastic;
#include <Generic\Interfaces\IComparable.mqh>

input int TPCoef, SLCoef;
input ENUM_TIMEFRAMES MAShortTimeframe, MALongTimeframe, CSTimeframe;
input int TrendPeriod,SLPeriod;
input int TPLine;
input int positionCloseMin;
bool tradable = false;
input int RangeTrendCri, LongTrendCri;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyTrade myTrade();
MyPrice myPrice(MAShortTimeframe, 10);
MyOrder myOrder(MAShortTimeframe);
CurrencyStrength CS(CSTimeframe, 1);;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   MyUtils myutils(60 * 27);
   myutils.Init();

   ciMAShort.Create(_Symbol, MAShortTimeframe, 8, 0, MODE_EMA, PRICE_CLOSE);
   ciMAMiddle.Create(_Symbol, MAShortTimeframe, 13, 0, MODE_EMA, PRICE_CLOSE);
   ciMALong.Create(_Symbol, MAShortTimeframe, 21, 0, MODE_EMA, PRICE_CLOSE);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   Refresh();
   ciMAShort.Refresh();
   ciMALong.Refresh();
   ciMAMiddle.Refresh();
   Check();


   double ShortTrend = ciMAShort.Main(0) - ciMAShort.Main(TrendPeriod);
   double MiddleTrend = ciMAShort.Main(0) - ciMAShort.Main(TrendPeriod);
   double LongTrend = ciMALong.Main(0) - ciMALong.Main(TrendPeriod);
  

   if(isBetween(ciMAShort.Main(0), ciMAMiddle.Main(0), ciMALong.Main(0))) {
      if(myPrice.getData(1).low < ciMAShort.Main(0) && myPrice.getData(1).close > ciMAShort.Main(1))
         myTrade.signal = "buy";
   }

   if(isBetween(ciMALong.Main(0), ciMAMiddle.Main(0), ciMAShort.Main(0))) {
      if(myPrice.getData(1).high > ciMAShort.Main(0) && myPrice.getData(1).close < ciMAShort.Main(1))
         myTrade.signal = "sell";
   }


   myPosition.CloseAllPositionsInMinute(positionCloseMin);

   if(!myTrade.istradable || !tradable) return;

   double PriceUnit = 10 * _Point;
   if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions / 2 && myTrade.signal == "buy") {
      double SL  = myPrice.Lowest(1, SLPeriod) - 30*_Point;
      double TP = myPrice.Higest(1,SLPeriod) + TPLine * _Point;
      if(myTrade.isInvalidTrade(SL, TP)) return;
      trade.Buy(myTrade.lot, NULL, myTrade.Ask, SL, TP, NULL);
   }

   if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions / 2 && myTrade.signal == "sell") {
      double TP  = myPrice.Lowest(1, SLPeriod) - TPLine * _Point;
      double SL = myPrice.Higest(1,SLPeriod) + 30*_Point;
      if(myTrade.isInvalidTrade(SL, TP)) return;
      trade.Sell(myTrade.lot, NULL, myTrade.Bid, SL, TP, NULL);
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
   double result =  myTest.min_dd_and_mathsqrt_profit_trades();
   return  result;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Refresh() {
   myPosition.Refresh();
   myTrade.Refresh();
   myPrice.Refresh();
   myOrder.Refresh();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Check() {
   myTrade.CheckSpread();
   //myTrade.CheckUntradableTime("01:00","07:00");
   //myTrade.CheckTradableTime("00:00","07:00");
   //myTrade.CheckTradableTime("08:00", "14:00");
   //myTrade.CheckTradableTime("14:00","24:00");
   if(myOrder.wasOrderedInTheSameBar()) myTrade.istradable = false;
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
