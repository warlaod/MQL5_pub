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
#include <Indicators\BillWilliams.mqh>
CiMomentum ciMomentum;
CiRSI ciRSI;
CTrade trade;

CiATR ciATR;
CiMA ciMA;
CiAMA ciAMA;

CiBearsPower ciBear;
CiBullsPower ciBull;
CiADX ciADX;
CiGator ciGator;
CiAlligator ciAlligator;

input ENUM_TIMEFRAMES GatorTimeframe;
input ENUM_MA_METHOD GatorMaMethod;
input ENUM_APPLIED_PRICE GatorAppliedPrice;
input int SL, TP;
input int BearRange,Long,Middle,Short;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyTrade myTrade(0.1, false);

bool JawTeeth, JawLips, TeethLips = false;


bool tradable = true;
int OnInit() {
   MyUtils myutils(13400, 60 * 20);
   myutils.Init();

   ciAlligator.Create(_Symbol, GatorTimeframe, Long, 0, Middle, 0, Short, 0, GatorMaMethod, GatorAppliedPrice);

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   

   ciAlligator.Refresh();

   int BearTrend = 0;
   for(int i = 1; i < BearRange; i++ ) {
      if(isBetween(ciAlligator.Jaw(i), ciAlligator.Teeth(i),ciAlligator.Lips(i))) BearTrend++;
   }
   TeethLips = false;
   if(BearTrend == BearRange - 1) {
      if(ciAlligator.Teeth(0) > ciAlligator.Lips(0)) {
         TeethLips = true;
      }
   }
   
   myTrade.Refresh();
   myTrade.CheckSpread();
   if(!myTrade.istradable || !tradable) return;

   myPosition.Refresh();
   if(myPosition.Total >= positions / 2) return;

   if(TeethLips) {
      trade.Buy(myTrade.lot, NULL, myTrade.Ask, myTrade.Ask - SL * _Point, myTrade.Ask + TP * _Point, NULL);
      TeethLips = false;
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
      tradable = false;
   }
}
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
