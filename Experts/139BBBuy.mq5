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


CiMomentum ciMomentum;
CiRSI ciRSI;
CTrade trade;

CiATR ciATR;
CiMA ciMA;
CiAMA ciAMA;
CiBands ciBand;


input ENUM_TIMEFRAMES BandTimeframe;
input int BandWidthRange;
input ENUM_APPLIED_PRICE BandAppliedPrice;
input int BandPeriod,Deviation;
input double  BandWidthCoef,CandleCoef;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPrice myPrice(BandTimeframe, 3);
MyPosition myPosition;
MyTrade myTrade(0.1, false);

bool tradable = true;
int OnInit() {
   MyUtils myutils(13400, 60 * 20);
   myutils.Init();
   ciBand.Create(_Symbol, BandTimeframe, BandPeriod, 0, Deviation, BandAppliedPrice);

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
// ATR, top.bottomはhighest-lowest
void OnTimer() {
   myPrice.Refresh();
   myPosition.Refresh();
   myTrade.Refresh();

   tradable = true;

   myTrade.CheckFridayEnd();
   myTrade.CheckYearsEnd();
   myTrade.CheckBalance();

   if(!myTrade.istradable) {
      myPosition.CloseAllPositions(POSITION_TYPE_BUY);
      tradable = false;
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   myTrade.Refresh();
   myTrade.CheckSpread();
   if(!myTrade.istradable || !tradable) return;

   myPosition.Refresh();
   if(myPosition.Total >= positions / 2) return;

   ciATR.Refresh();
   ciMA.Refresh();
   ciAMA.Refresh();
   myPrice.Refresh();
   ciBand.Refresh();




   if(ciBand.Lower(1) < myPrice.getData(1).low) return;
   if(myPrice.getData(1).close - myPrice.getData(1).open > 0) return;
   if(myPrice.getData(0).close - myPrice.getData(0).open < 0) return;
   
   if(myPrice.getData(0).close - myPrice.getData(0).open > MathAbs(myPrice.getData(1).close - myPrice.getData(1).open)*CandleCoef)

   trade.Buy(myTrade.lot, NULL, myTrade.Ask, ciBand.Lower(0) - 50 * _Point, ciBand.Upper(0), NULL);
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
