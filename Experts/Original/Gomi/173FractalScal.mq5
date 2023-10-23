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
CTrade trade;
CiFractals ciFractals;
CiATR ciATR;

input ENUM_TIMEFRAMES FractalTimeframe;
input double TPCoef, SLCoef;
input int FractalPeriod;
input int SignalCri,ATRCri;
bool tradable = false;
string LTrend;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyTrade myTrade();
MyPrice myPrice(FractalTimeframe, 2);

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   MyUtils myutils(60 * 27);
   myutils.Init();
   ciFractals.Create(_Symbol, FractalTimeframe);
   ciATR.Create(_Symbol,FractalTimeframe,14);

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   myPosition.Refresh();
   ciFractals.Refresh();
   ciATR.Refresh();
   myTrade.Refresh();
   myPrice.Refresh();


   myTrade.CheckSpread();
   
   if(!myTrade.istradable || !tradable) return;

   CArrayDouble UpperFractals;
   CArrayDouble LowerFractals;
   for(int i = 0; i < FractalPeriod; i++) {
      if(ciFractals.Upper(i) != EMPTY_VALUE) UpperFractals.Add(ciFractals.Upper(i));
      if(ciFractals.Lower(i) != EMPTY_VALUE) LowerFractals.Add(ciFractals.Lower(i));
   }

   if(ciATR.Main(0) < ATRCri*_Point) return;

   double HighestFractal = UpperFractals.At(UpperFractals.Maximum(0, FractalPeriod));
   double LowestFractal = LowerFractals.At(LowerFractals.Minimum(0, FractalPeriod));
  

   if(HighestFractal < myPrice.getData(0).close + SignalCri * _Point) myTrade.signal = "buy";

   if(LowestFractal > myPrice.getData(0).close - SignalCri * _Point) myTrade.signal = "sell";


   double PriceUnit = 10 * _Point;
   if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions / 2 && myTrade.signal == "buy") {
      if(myTrade.isInvalidTrade(LowestFractal - PriceUnit * SLCoef, myTrade.Ask + PriceUnit  * TPCoef)) return;
      trade.Buy(myTrade.lot, NULL, myTrade.Ask, LowestFractal - PriceUnit * SLCoef, myTrade.Ask + PriceUnit  * TPCoef, NULL);
   }

   if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions / 2 && myTrade.signal == "sell") {
      if(myTrade.isInvalidTrade(HighestFractal + PriceUnit * SLCoef, myTrade.Bid - PriceUnit * TPCoef)) return;
      trade.Sell(myTrade.lot, NULL, myTrade.Bid, HighestFractal + PriceUnit * SLCoef, myTrade.Bid - PriceUnit * TPCoef, NULL);
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
