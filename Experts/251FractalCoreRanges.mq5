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
input mis_MarcosTMP timeFrame;
ENUM_TIMEFRAMES Timeframe = defMarcoTiempo(timeFrame);
input int MiddlePositions, ShortPositions;
input int MiddleSL, ShortSL;
bool tradable = false;
double PriceToPips = PriceToPips();
double pips = ToPips();
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyTrade myTrade();
MyDate myDate();
MyPrice myPrice(Timeframe, 3);
MyOrder myOrder(Timeframe);
CurrencyStrength CS(Timeframe, 1);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyFractal myFractal();
int OnInit() {
   MyUtils myutils(60 * 1);
   myutils.Init();
   myFractal.Create(_Symbol, Timeframe);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void buy(double SL, double Range) {
   if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions) {
      if(myPosition.isPositionInRange(POSITION_TYPE_BUY, Range)) return;
      myTrade.Buy(SL, myTrade.Ask + Range);
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void sell(double SL, double Range) {
   if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions) {
      if(myPosition.isPositionInRange(POSITION_TYPE_SELL, Range)) return;
      myTrade.Sell(SL, myTrade.Bid - Range);
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer() {

   {
      Refresh();
      Check();

      myFractal.myRefresh();
      myFractal.SearchMiddle();
      myPrice.Refresh();
      
      if(!myFractal.isMSLinedCorrectly()) return;

      double MiddleGap = myFractal.fractal(Middle, Up, 0) - myFractal.fractal(Middle, Low, 0);
      double ShortGap = myFractal.fractal(Short, Up, 0) - myFractal.fractal(Short, Low, 0);

      if(myFractal.isRecentShortFractal(Up))
         myTrade.setSignal(ORDER_TYPE_SELL);
      if(myFractal.isRecentShortFractal(Low))
         myTrade.setSignal(ORDER_TYPE_BUY);

      double Range, SL;
      if(isBetween(myFractal.fractal(Middle, Up, 0), myPrice.At(0).close, myFractal.fractal(Short, Up, 0))) {
         Range = MiddleGap / MiddlePositions;
         sell(myFractal.fractal(Middle, Up, 0) + MiddleSL * pips, Range);
      }

      if(isBetween(myFractal.fractal(Short, Up, 0), myPrice.At(0).close, myFractal.fractal(Short, Low, 0))) {
         Range = ShortGap / ShortPositions;
         sell(myFractal.fractal(Short, Up, 0) + ShortSL * pips, Range);
         buy(myFractal.fractal(Short, Low, 0) - ShortSL * pips, Range);
      }

      if(isBetween(myFractal.fractal(Short, Low, 0), myPrice.At(0).close, myFractal.fractal(Middle, Low, 0))) {
         Range = MiddleGap / MiddlePositions;
         buy(myFractal.fractal(Middle, Low, 0) - MiddleSL * pips, Range);
      }
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
double OnTester() {
   MyTest myTest;
   double result =  myTest.min_dd_and_mathsqrt_trades();
   return  result;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Refresh() {
   myPosition.Refresh();
   myTrade.Refresh();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Check() {
   //myTrade.CheckSpread();
   myDate.Refresh();
   myOrder.Refresh();
   if(myDate.isMondayStart()) myTrade.isCurrentTradable = false;
   if(myOrder.wasOrderedInTheSameBar()) myTrade.isCurrentTradable = false;
}
//+------------------------------------------------------------------+
