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
CiRSI ciRSIShort,ciRSIMiddle,ciRSILong;
CiATR ciATR;
input ENUM_TIMEFRAMES RSIShortTimeframe,RSIMiddleTimeframe,RSILongTimeframe;
input int RSIBuyTOPCri,RSIBuyBottomCri,RSISellTOPCri,RSISellBottomCri,RSILongMiddleDiff,ATRCri;
input int RSIPeriod,ATRPeriod;
input ENUM_APPLIED_PRICE RSIAppliedPrice;
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

   ciRSIShort.Create(_Symbol,RSIShortTimeframe,RSIPeriod,RSIAppliedPrice);
   ciRSIMiddle.Create(_Symbol,RSIMiddleTimeframe,RSIPeriod,RSIAppliedPrice);
   ciRSILong.Create(_Symbol,RSILongTimeframe,RSIPeriod,RSIAppliedPrice);
   ciATR.Create(_Symbol, RSIShortTimeframe, ATRPeriod);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   myPosition.Refresh();
   ciRSIShort.Refresh();
   ciRSIMiddle.Refresh();
   ciRSILong.Refresh();
   ciATR.Refresh();
   myTrade.Refresh();
   
   if(MathAbs(ciRSILong.Main(0) - ciRSIMiddle.Main(0)) < RSILongMiddleDiff) return;
   
   myTrade.CheckSpread();

   if(!myTrade.istradable || !tradable) return;
   
   if(isBetween(ciRSIShort.Main(0),ciRSILong.Main(0),ciRSIMiddle.Main(0)) && isBetween(ciRSILong.Main(1),ciRSIShort.Main(1),ciRSIMiddle.Main(1))){
      myTrade.signal = "buy";
   }
   
   if(isBetween(ciRSIMiddle.Main(0),ciRSILong.Main(0),ciRSIShort.Main(0)) && isBetween(ciRSIMiddle.Main(1),ciRSIShort.Main(1),ciRSILong.Main(1))){
      myTrade.signal = "sell";
   }
   
   
   
   
   double PriceUnit = ciATR.Main(0);
   if(PriceUnit < ATRCri*_Point) return;
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
   if(!isBetween(RSILongTimeframe,RSIMiddleTimeframe,RSIShortTimeframe)) return -99999999;
   return  result;
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
