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
 #include <Expert\Trailing\TrailingFixedPips.mqh>
CTrailingFixedPips ctfp;
CiMomentum ciMomentum;
CTrade trade;

CiATR ciATR;
CiOsMA ciOsma;

CiBearsPower ciBear;
CiBullsPower ciBull;
CiADX ciADX;

input ENUM_TIMEFRAMES ADXTimeframe;
input ENUM_APPLIED_PRICE OsmaAppleidPrice;
input double SLCoef,TPCoef,OsmaCri,ATRCri;
input int ADXPeriod;
input int ADXCri;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyTrade myTrade();

bool tradable = true;
int OnInit() {
   MyUtils myutils(60 * 27);
   myutils.Init();
   

   ciADX.Create(_Symbol, ADXTimeframe, ADXPeriod);
   ciATR.Create(_Symbol, ADXTimeframe, 14);
   ciOsma.Create(_Symbol,ADXTimeframe,12,26,9,OsmaAppleidPrice);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   
   myTrade.Refresh();
   if(!myTrade.istradable || !tradable) return;

   myPosition.Refresh();

   ciATR.Refresh();
   ciADX.Refresh();
   ciOsma.Refresh();
   
   double currentATR = ciATR.Main(0);
   
   if(currentATR < pow(10,ATRCri)) return;
   if(ciADX.Main(0) < ADXCri) return;
   if(ciADX.Main(0) < ciADX.Main(1)) return;
   if(ciADX.Plus(1) < ciADX.Main(1) && ciADX.Plus(0) > ciADX.Main(0) && ciOsma.Main(0) > pow(10,OsmaCri)) myTrade.signal = "buy";
   else if(ciADX.Minus(1) < ciADX.Main(1) && ciADX.Minus(0) > ciADX.Main(0) && ciOsma.Main(0) < -pow(10,OsmaCri)) myTrade.signal = "sell";
   
   
   
   if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions/2 && myTrade.signal=="buy")
     {
      trade.Buy(myTrade.lot,NULL,myTrade.Ask,myTrade.Ask-currentATR*SLCoef,myTrade.Ask+currentATR*TPCoef,NULL);
     }

   if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions/2 && myTrade.signal=="sell")
     {
      trade.Sell(myTrade.lot,NULL,myTrade.Bid,myTrade.Bid+currentATR*SLCoef,myTrade.Bid-currentATR*TPCoef,NULL);
     }
     
}
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
