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
CiMA ciMALong, ciMAShort;
CiBands ciBands;
CiStochastic ciStochastic;
#include <Generic\Interfaces\IComparable.mqh>

input int TPCoef, SLCoef;
input int TrendPeriod,MAPeriod;
input ENUM_TIMEFRAMES MAShortTimeframe;
input int positionCloseMin;
bool tradable = false;
input int TrendCri;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyTrade myTrade();
MyPrice myPrice(MAShortTimeframe, 10);
MyOrder myOrder;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   MyUtils myutils(60 * 27);
   myutils.Init();

   ciMAShort.Create(_Symbol, MAShortTimeframe, 10, 0, MODE_SMA, PRICE_CLOSE);
   ciMALong.Create(_Symbol, MAShortTimeframe, 10*MAPeriod, 0, MODE_SMA, PRICE_CLOSE);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {

   myPosition.Refresh();
   myTrade.Refresh();
   myPrice.Refresh();
   ciMALong.Refresh();
   ciMAShort.Refresh();

   myTrade.CheckSpread();
   myOrder.Refresh();

   myPosition.CloseAllPositionsInMinute(positionCloseMin);
   if(!tradable) return;
   myTrade.CheckTradableTime("08:00","14:00");
   if(myOrder.wasOrderedInTheSameBar(MAShortTimeframe)) myTrade.istradable = false;
   if(!myTrade.istradable) return;



   double LongTrend = ciMALong.Main(0) - ciMALong.Main(TrendPeriod*MAPeriod);
   double ShortTrend = ciMAShort.Main(0) - ciMAShort.Main(10);
   //if(MathAbs(LongTrend) > TrendCri * _Point) return;

   if(ciMALong.Main(0) < ciMAShort.Main(0)) {
      if(isBetween(myPrice.getData(2).close, ciMAShort.Main(2), ciMALong.Main(2)) && isBetween(ciMAShort.Main(1), myPrice.getData(1).close, ciMALong.Main(1))) {
         myTrade.signal = "sell";
      }
   }

   if(ciMALong.Main(0) > ciMAShort.Main(0)) {
      if(isBetween( ciMALong.Main(2), ciMAShort.Main(2), myPrice.getData(2).close) && isBetween(ciMALong.Main(1), myPrice.getData(1).close, ciMAShort.Main(1) )) {
         myTrade.signal = "buy";
      }
   }

   double PriceUnit = 10 * _Point;
   if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions / 2 && myTrade.signal == "buy") {
      double SL = myPrice.Lowest(0, 7)- 20*_Point;
      if(myTrade.isInvalidTrade(SL, ciMALong.Main(0))) return;
      trade.Buy(myTrade.lot, NULL, myTrade.Ask, SL, ciMALong.Main(0), NULL);
   }

   if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions / 2 && myTrade.signal == "sell") {
      double SL = myPrice.Higest(0, 7)+ 20*_Point;
      if(myTrade.isInvalidTrade(SL, ciMALong.Main(0))) return;
      trade.Sell(myTrade.lot, NULL, myTrade.Bid, SL, ciMALong.Main(0), NULL);
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

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
