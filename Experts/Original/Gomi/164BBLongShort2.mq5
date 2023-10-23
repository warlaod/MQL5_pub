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
CTrade trade;
CiStochastic ciStochastic;
CiSAR ciSAR;
CiBands ciLongBands, ciShortBands;
CiATR ciATR;

input ENUM_TIMEFRAMES BandLongTimeframe, BandShortTimeframe;
input int BandShortPeriod, BandLongPeriod, Deviation;
input ENUM_APPLIED_PRICE BandAppliedPrice;
input double TPCoef, SLCoef;
bool tradable = false;
string preSignal;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyTrade myTrade(0.1, false);
MyPrice myPrice(BandLongTimeframe, 3);

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   MyUtils myutils(14100, 60 * 27);
   myutils.Init();

   ciLongBands.Create(_Symbol, BandLongTimeframe, BandShortPeriod, 0, Deviation, BandAppliedPrice);
   ciShortBands.Create(_Symbol, BandShortTimeframe, BandLongPeriod, 0, Deviation, BandAppliedPrice);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   myPosition.Refresh();
   ciLongBands.Refresh();
   ciShortBands.Refresh();
   myTrade.Refresh();
   
   if(BandLongTimeframe <= BandShortTimeframe) return;

   if(!myTrade.istradable || !tradable) return;
   
   double dwadwa = ciLongBands.Upper(1);
   double awdwa  = ciShortBands.Upper(0);
   if(ciLongBands.Upper(1) > ciShortBands.Upper(1) && ciLongBands.Upper(0) < ciShortBands.Upper(0)){
      preSignal = "buy";
   }
   if(ciLongBands.Lower(1) < ciShortBands.Lower(1) && ciLongBands.Lower(0) > ciShortBands.Lower(0)){
      preSignal = "sell";
   }
   
   if(ciLongBands.Upper(1) < ciShortBands.Upper(1)&& ciLongBands.Upper(0) > ciShortBands.Upper(0) && preSignal =="buy"){
      myTrade.signal = "buy";
      preSignal = "";
   }
   if(ciLongBands.Lower(1) > ciShortBands.Lower(1) && ciLongBands.Lower(0) < ciShortBands.Lower(0) && preSignal =="sell"){
      myTrade.signal = "sell";
      preSignal = "";
   }

   double PriceUnit = MathAbs(ciLongBands.Base(0) - ciShortBands.Base(0));
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
