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
input int ADXPeriod;
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
CiADX ADX;
int OnInit() {
   MyUtils myutils(60 * 50);
   myutils.Init();
   myFractal.Create(_Symbol, Timeframe);
   ADX.Create(_Symbol, Timeframe, ADXPeriod);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   Refresh();
   Check();

   //myPosition.CloseAllPositionsInMinute();
   if(!myTrade.isCurrentTradable || !myTrade.isTradable) return;

   myFractal.myRefresh();
   myFractal.SearchMiddle();

   double MiddleGap = myFractal.fractal(Middle, Up, 0) - myFractal.fractal(Middle, Low, 0);
   double FractalPerB = (myPrice.At(0).close - myFractal.fractal(Middle, Low, 0)) / MiddleGap;

   if(ADX.Main(0) < 20) return;
   if(!isBetween(ADX.Main(0), ADX.Main(1), ADX.Main(2))) return;

   if(ADX.Plus(0) > 20) {
      if(isBetween(ADX.Plus(0), ADX.Plus(1), ADX.Plus(2)))
         myTrade.setSignal(ORDER_TYPE_BUY);
   }

   if(ADX.Minus(0) > 20) {
      if(isBetween(ADX.Minus(0), ADX.Minus(1), ADX.Minus(2)))
         myTrade.setSignal(ORDER_TYPE_BUY);
   }

   double PriceUnit = MiddleGap;

   if(!myPosition.isPositionInRange(POSITION_TYPE_BUY, MiddleGap * TPCoef)) {
      myTrade.Buy(myTrade.Ask - PriceUnit * SLCoef, myTrade.Ask + PriceUnit * TPCoef);
   }

   if(!myPosition.isPositionInRange(POSITION_TYPE_SELL, MiddleGap * TPCoef)) {
      myTrade.Sell(myTrade.Bid + PriceUnit * SLCoef, myTrade.Bid - PriceUnit * TPCoef);
   }



}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer() {
   myPosition.Refresh();
   myTrade.Refresh();
   myDate.Refresh();

   if(myDate.isFridayEnd() || myDate.isYearEnd() || myTrade.isLowerBalance() || myTrade.isLowerMarginLevel()) {
      myPosition.CloseAllPositions(POSITION_TYPE_BUY);
      myPosition.CloseAllPositions(POSITION_TYPE_SELL);
      myTrade.isTradable = false;
   } else {
      myTrade.isTradable = true;
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
