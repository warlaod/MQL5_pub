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
CiMomentum ciMomentum;
CiRSI ciRSI;
CTrade trade;

CiATR ciATR;
CiMA ciMA;
CiAMA ciAMA;

CiBearsPower ciBear;
CiBullsPower ciBull;
CiADX ciADX;

input ENUM_TIMEFRAMES ADXTimeframe, BullTimeframe;
input int BullPeriod, BullDeclineRange;
input int SL,TP;
input int BullCri;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyTrade myTrade(0.1, false);

bool tradable = true;
int OnInit() {
   MyUtils myutils(13400, 60 * 20);
   myutils.Init();

   ciADX.Create(_Symbol, ADXTimeframe, 14);
   ciBull.Create(_Symbol, BullTimeframe, BullPeriod);

   return(INIT_SUCCEEDED);
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

   ciBull.Refresh();
   ciADX.Refresh();

   if(ciADX.Minus(0) > ciADX.Minus(1)) return;
   for(int i = 1; i < BullDeclineRange; i++) {
      if(ciBull.Main(i) > 0) return;
      if(ciBull.Main(i) > ciBull.Main(i + 1)) return;
   }
   if(ciBull.Main(0) > -BullCri*_Point) return;

   trade.Buy(myTrade.lot, NULL, myTrade.Ask, myTrade.Ask - SL * _Point, myTrade.Ask + TP * _Point, NULL);
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
