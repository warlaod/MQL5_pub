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
#include <Original\prices.mqh>
#include <Original\positions.mqh>
#include <Original\period.mqh>
#include <Original\account.mqh>
#include <Original\caluculate.mqh>
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
CiAO ciLongAO,ciShortAO;
input ENUM_TIMEFRAMES AOShotTimeframe,AOLongTimeframe;
input int MaxValRange,ShortAOCri,LongAOCri;
input double TPCoef,SLCoef;
bool tradable = false;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyTrade myTrade(0.1, false);

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   MyUtils myutils(14100, 60 * 27);
   myutils.Init();

   ciLongAO.Create(_Symbol,AOLongTimeframe);
   ciShortAO.Create(_Symbol,AOShotTimeframe);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   myPosition.Refresh();
   ciShortAO.Refresh();
   ciLongAO.Refresh();
   myTrade.Refresh();
   
   double MaxVal,MinVal;
   int MinIndex,MaxIndex;
   MaxVal = ciShortAO.MaxValue(0,0,MaxValRange,MaxIndex);
   MinVal = ciShortAO.MinValue(0,0,MaxValRange,MinIndex);
   if(ciShortAO.Main(1) > MaxVal) myPosition.CloseAllPositions(POSITION_TYPE_SELL);
   if(ciShortAO.Main(1) < MinVal) myPosition.CloseAllPositions(POSITION_TYPE_BUY);
   
   if(!myTrade.istradable || !tradable) return;
   if(!isBetween(MathAbs(ciLongAO.Main(2)),MathAbs(ciLongAO.Main(1)),MathAbs(ciLongAO.Main(0)))) return;
   if(!isBetween(MathAbs(ciShortAO.Main(2)),MathAbs(ciShortAO.Main(3)),MathAbs(ciShortAO.Main(4)))) return;
   if(MathAbs(ciShortAO.Main(0)) < ShortAOCri*_Point) return;
   if(MathAbs(ciLongAO.Main(0)) < LongAOCri*_Point) return;
   
   if(MaxIndex !=2 && MinIndex !=2) return;
   if(ciLongAO.Main(0) < 0){
      myTrade.signal ="sell"; 
   }else if(ciLongAO.Main(0) > 0){
      myTrade.signal ="buy"; 
   }
   
   

   if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions / 2 && myTrade.signal == "buy") {
      if(myTrade.isInvalidTrade(myTrade.Ask - ciShortAO.Main(0) * SLCoef, myTrade.Ask + ciShortAO.Main(0)  * TPCoef)) return;
      trade.Buy(myTrade.lot, NULL, myTrade.Ask, myTrade.Ask - ciShortAO.Main(0) * SLCoef, myTrade.Ask + ciShortAO.Main(0)  * TPCoef, NULL);
   }

   if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions / 2 && myTrade.signal == "sell") {
      if(myTrade.isInvalidTrade(myTrade.Bid + ciShortAO.Main(0) * SLCoef, myTrade.Bid - ciShortAO.Main(0) * TPCoef)) return;
      trade.Sell(myTrade.lot, NULL, myTrade.Bid, myTrade.Bid + ciShortAO.Main(0) * SLCoef, myTrade.Bid - ciShortAO.Main(0) * TPCoef, NULL);
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
