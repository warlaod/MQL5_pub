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
#include <Indicators\TimeSeries.mqh>
#include <Indicators\Oscilators.mqh>
#include <Indicators\Trend.mqh>
#include <Trade\OrderInfo.mqh>
#include <Arrays\ArrayDouble.mqh>
#include <Indicators\BillWilliams.mqh>
#include <Arrays\ArrayDouble.mqh>
CTrade trade;
CiRSI ciRSI, ciRSIMiddle, ciRSILong;
CiATR ciATR;
CiBands ciBands;
input ENUM_TIMEFRAMES RSITimeframe;
input int RSIDiffCri;
input int RSIPeriod, BandPeriod, TrailingPeriod;
input int SLCount, TPCount;
input ENUM_APPLIED_PRICE RSIAppliedPrice, BandAppliedPrice;
bool tradable = false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyTrade myTrade();
MyPrice myPrice(RSITimeframe, 100);

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   MyUtils myutils(60 * 27);
   myutils.Init();
   trade.SetExpertMagicNumber(MagicNumber);

   ciRSI.Create(_Symbol, RSITimeframe, 14, RSIAppliedPrice);
   ciBands.Create(_Symbol, RSITimeframe, 20, 0, 2, BandAppliedPrice);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   myPosition.Refresh();
   ciRSI.Refresh();
   ciBands.Refresh();
   myTrade.Refresh();
   myPrice.Refresh();

   if(MathAbs(ciRSI.Main(1) - ciRSI.Main(0)) < RSIDiffCri) return;

   if(!myTrade.istradable || !tradable) return;

   if(ciBands.Upper(1) <  myPrice.getData(1).high ) {
      if(ciRSI.Main(1) > 70 && ciRSI.Main(1) > ciRSI.Main(0) && myPrice.getData(1).close > myPrice.getData(0).close) {
         myTrade.signal = "sell";
      }
   }

   if(ciBands.Lower(1) > myPrice.getData(1).low ) {
      if(ciRSI.Main(1) < 30 && ciRSI.Main(1) < ciRSI.Main(0) && myPrice.getData(1).close < myPrice.getData(0).close) {
         myTrade.signal = "buy";
      }
   }

   if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions / 2 && myTrade.signal == "buy") {
      double TP = myPrice.Higest(TPCount);
      double SL = myPrice.Lowest(SLCount);
      if(myTrade.isInvalidTrade(SL, TP )) return;
      trade.Buy(myTrade.lot, NULL, myTrade.Ask, SL, TP, NULL);
   }

   if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions / 2 && myTrade.signal == "sell") {
      double TP = myPrice.Lowest(TPCount);
      double SL = myPrice.Higest(SLCount);
      if(myTrade.isInvalidTrade(SL, TP ) )return;
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

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
