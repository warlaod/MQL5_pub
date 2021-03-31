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
#include <Original\MyUtils.mqh>
#include <Original\MyTrade.mqh>
#include <Original\Oyokawa.mqh>
#include <Original\MyDate.mqh>
#include <Original\MyCalculate.mqh>
#include <Original\MyTest.mqh>
#include <Original\MyPrice.mqh>
#include <Original\MyPosition.mqh>
#include <Original\MyOrder.mqh>
#include <Original\MyHistory.mqh>
#include <Original\MyCHart.mqh>
#include <Original\MyFractal.mqh>
#include <Original\Optimization.mqh>
#include <Indicators\TimeSeries.mqh>
#include <Indicators\Oscilators.mqh>
#include <Indicators\Trend.mqh>
#include <Indicators\BillWilliams.mqh>
#include <Indicators\Volumes.mqh>
#include <Trade\PositionInfo.mqh>
#include <ChartObjects\ChartObjectsLines.mqh>

input double SLCoef, TPCoef;
input mis_MarcosTMP timeFrame, adxTimeFrame;
ENUM_TIMEFRAMES Timeframe = defMarcoTiempo(timeFrame);
ENUM_TIMEFRAMES ADXTimeframe = defMarcoTiempo(adxTimeFrame);
bool tradable = false;
double PriceToPips = PriceToPips();
double pips = PointToPips();
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyTrade myTrade();
MyDate myDate(Timeframe);
MyPrice myPrice(Timeframe);
MyHistory myHistory(Timeframe);
MyOrder myOrder(myDate.BarTime);
CurrencyStrength CS(Timeframe, 1);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyFractal myF;
CiADX ADX;
int OnInit() {
   MyUtils myutils(60 * 50);
   myutils.Init();
   myF.Create(_Symbol, Timeframe);
   ADX.Create(_Symbol, ADXTimeframe, 14);
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   IsCurrentTradable = true;
   Signal = -1;
   Check();
   //myOrder.Refresh();
   //myPosition.CloseAllPositionsInMinute();
   myPosition.Refresh();
   myF.myRefresh();
   myF.SearchMiddle();
   double SLow = myF.fractal(Short, Low);
   double SUp =  myF.fractal(Short, Up);
   myPosition.CheckTargetPriceProfitableForTrailings(POSITION_TYPE_BUY, SLow);
   myPosition.CheckTargetPriceProfitableForTrailings(POSITION_TYPE_SELL, SUp);
   myPosition.Trailings(POSITION_TYPE_BUY, SLow);
   myPosition.Trailings(POSITION_TYPE_BUY, SUp);
   if(!IsCurrentTradable || !IsTradable) return;

   ADX.Refresh();
   if(ADX.Main(0) < 20) return;
   if(!isBetween(ADX.Main(0), ADX.Main(1), ADX.Main(2))) return;



   if(ADX.Plus(0) > 20) {
      if(myF.isRecentShortFractal(Low))
         setSignal(ORDER_TYPE_BUY);
   } else if(ADX.Minus(0) > 20) {
      if(myF.isRecentShortFractal(Up))
         setSignal(ORDER_TYPE_SELL);
   }
   double PriceUnit = pips;
   if(Signal == -1) return;

   myTrade.Refresh();

   if(Signal == ORDER_TYPE_BUY) {
      if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions) {
         myTrade.Buy(myF.fractal(Short, Low), 100000);
      }
   } else if(Signal == ORDER_TYPE_SELL) {
      if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions) {
         myTrade.Sell(myF.fractal(Short, Up), 0);
      }
   }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer() {
   myDate.Refresh();
   IsTradable = true;
   if(myDate.isFridayEnd() || myDate.isYearEnd()) {
      myPosition.Refresh();
      myPosition.CloseAllPositions(POSITION_TYPE_BUY);
      myPosition.CloseAllPositions(POSITION_TYPE_SELL);
      IsTradable = false;
   } else if(myTrade.isLowerBalance() || myTrade.isLowerMarginLevel()) {
      myPosition.Refresh();
      myPosition.CloseAllPositions(POSITION_TYPE_BUY);
      myPosition.CloseAllPositions(POSITION_TYPE_SELL);
      Print("EA stopped because of lower balance or lower margin level  ");
      ExpertRemove();
   }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double OnTester() {
   MyTest myTest;
   double result =  myTest.min_dd_and_mathsqrt_trades();
   return  result;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Check() {
   //myTrade.CheckSpread();
   myDate.Refresh();
   myHistory.Refresh();
   if(myDate.isMondayStart()) IsCurrentTradable = false;
   else if(myHistory.wasOrderedInTheSameBar()) IsCurrentTradable = false;
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
