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
CiRSI ciRSIShort, ciRSIMiddle, ciRSILong;
CiATR ciATR;
CiMA ciMA;
input ENUM_TIMEFRAMES MATimeframe;
input int MAPeriod;
input int TrendRange;
input int  WeakTrendCri,  priceCount, PriceDistanceCri, SignalPriceCri;
input ENUM_APPLIED_PRICE MAAppliedPrice;
input double TPCoef, SLCoef;
bool tradable = false;

string PreTrend;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyTrade myTrade();
MyPrice myPrice(MATimeframe, priceCount);

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   MyUtils myutils(60 * 27);
   myutils.Init();



   ciMA.Create(_Symbol, MATimeframe, MAPeriod, 0, MODE_EMA, MAAppliedPrice);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   myPosition.Refresh();
   ciMA.Refresh();
   myTrade.Refresh();
   myPrice.Refresh();

   if(MAPeriod < TrendRange) return;

   if(!myTrade.istradable || !tradable) return;

   double CurTrend = ciMA.Main(0) - ciMA.Main(TrendRange);

   double Highest = myPrice.Higest(1, priceCount);
   double Lowest = myPrice.Lowest(1, priceCount);

   if(Highest - Lowest > PriceDistanceCri * _Point) return;

   if(MathAbs(CurTrend) > WeakTrendCri * _Point) return;
   if(!myTrade.istradable || !tradable) return;


   if(myPrice.getData(0).close > Highest + SignalPriceCri * _Point) {
      if(CurTrend > 0) {
         myTrade.signal = "buy";
      }
   }
   if(myPrice.getData(0).close < Lowest - SignalPriceCri * _Point) {
      if(CurTrend < 0) {
         myTrade.signal = "sell";
      }
   }




   double PriceUnit = Highest - Lowest;
   if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions / 2 && myTrade.signal == "buy") {
      if(myTrade.isInvalidTrade(myTrade.Ask - PriceUnit * SLCoef, myTrade.Ask + PriceUnit  * TPCoef)) return;
      trade.Buy(myTrade.lot, NULL, myTrade.Ask, myTrade.Ask - PriceUnit * SLCoef, myTrade.Ask + PriceUnit  * TPCoef, NULL);
   }

   if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions / 2 && myTrade.signal == "sell") {
      if(myTrade.isInvalidTrade(myTrade.Bid + PriceUnit * SLCoef, myTrade.Bid - PriceUnit * TPCoef)) return;
      trade.Sell(myTrade.lot, NULL, myTrade.Bid, myTrade.Bid + PriceUnit * SLCoef, myTrade.Bid - PriceUnit * TPCoef, NULL);
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
