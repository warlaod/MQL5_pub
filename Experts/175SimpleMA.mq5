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
CiMA ciLongMA, ciShortMA;
CiFractals ciFractals;
CiATR ciATR;


input ENUM_TIMEFRAMES  MATimeframe;
input ENUM_MA_METHOD MA_MODE;
input ENUM_APPLIED_PRICE AppliedPrice;
input int LongPeriod, ShortPeriod;
input double TPCoef, SLCoef;
input int ATRCri;
bool tradable = false;
string LTrend;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyTrade myTrade();
MyPrice myPrice(MATimeframe, 2);

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   MyUtils myutils(60 * 27);
   myutils.Init();

   ciLongMA.Create(_Symbol, MATimeframe, LongPeriod, 0, MA_MODE, AppliedPrice);
   ciShortMA.Create(_Symbol, MATimeframe, ShortPeriod, 0, MA_MODE, AppliedPrice);
   ciATR.Create(_Symbol,MATimeframe,14);

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   myPosition.Refresh();
   ciLongMA.Refresh();
   ciShortMA.Refresh();
   ciATR.Refresh();
   myTrade.Refresh();
   myPrice.Refresh();


   myTrade.CheckSpread();

   if(!myTrade.istradable || !tradable) return;
   if(ShortPeriod >= LongPeriod) return;
   
   if(ciATR.Main(0) < ATRCri*_Point) return;
   
   
   
   if(ciLongMA.Main(1) > ciShortMA.Main(1) && ciLongMA.Main(0) < ciShortMA.Main(0)){
      myTrade.signal = "buy";
      myPosition.CloseAllPositions(POSITION_TYPE_SELL);
   }
   
   if(ciLongMA.Main(1) < ciShortMA.Main(1) && ciLongMA.Main(0) > ciShortMA.Main(0)){
      myTrade.signal = "sell";
      myPosition.CloseAllPositions(POSITION_TYPE_BUY);
   }
   
    double PriceUnit = 10*_Point;
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
