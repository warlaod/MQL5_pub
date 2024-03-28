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
input int ADXCri;
input int SLPeriod, TrailPeriod;
input mis_MarcosTMP timeFrame, adxTimeFrame, trailTimeframe, slTimeframe;
ENUM_TIMEFRAMES Timeframe = defMarcoTiempo(timeFrame);
ENUM_TIMEFRAMES ADXTimeframe = defMarcoTiempo(adxTimeFrame);
ENUM_TIMEFRAMES TrailTimeframe = defMarcoTiempo(trailTimeframe);
ENUM_TIMEFRAMES SLTimeframe = defMarcoTiempo(slTimeframe);
bool tradable = false;
double PriceToPips = PriceToPips();
double pips = PointToPips();
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyTrade myTrade();
MyDate myDate(Timeframe);
MyPrice myPrice(Timeframe), myTrailPrice(TrailTimeframe), mySLPrice(SLTimeframe);
MyHistory myHistory(Timeframe);
MyOrder myOrder(myDate.BarTime);
CurrencyStrength CS(Timeframe, 1);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CiWPR WPR;
CiADX ADX;
CiMA MA;
double Distance = MathPow(2, TPCoef);
int OnInit() {
   MyUtils myutils(60 * 1);
   myutils.Init();
   MA.Create(_Symbol, Timeframe, 10, 0, MODE_SMA, PRICE_TYPICAL);
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

   if(!IsCurrentTradable || !IsTradable) return;

   ADX.Refresh();
   if(ADX.Main(0) < ADXCri) return;
   if(isBetween(ADX.Main(0), ADX.Main(1), ADX.Main(2))) return;

   myPrice.Refresh(1);
   MA.Refresh();
   if(ADX.Plus(0) > 20) {
      if(MA.Main(0) > myPrice.At(0).close)
         setSignal(ORDER_TYPE_BUY);
   } else if(ADX.Minus(0) > 20) {
      if(MA.Main(0) < myPrice.At(0).close)
         setSignal(ORDER_TYPE_SELL);
   }

   double PriceUnit = pips;
   if(Signal == -1) return;

   myTrade.Refresh();
   myPosition.Refresh();
   if(Signal == ORDER_TYPE_BUY) {
      if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions) {
         if(myPosition.isPositionInRange(POSITION_TYPE_BUY, Distance)) return;
         myTrade.Buy(mySLPrice.Lowest(1, SLPeriod), 100000);
      }
   } else if(Signal == ORDER_TYPE_SELL) {
      if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions) {
         if(myPosition.isPositionInRange(POSITION_TYPE_SELL, Distance)) return;
         myTrade.Sell(mySLPrice.Highest(1, SLPeriod), 0);
      }
   }
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
//|                                                                  |
//+------------------------------------------------------------------+
void Trail() {
   myPosition.Refresh();
   double TrailLowest = myTrailPrice.Lowest(1, TrailPeriod);
   double TrailHighest = myTrailPrice.Highest(1, TrailPeriod);
   myPosition.CheckTargetPriceProfitableForTrailings(POSITION_TYPE_BUY, TrailLowest);
   myPosition.CheckTargetPriceProfitableForTrailings(POSITION_TYPE_SELL, TrailHighest);
   myPosition.Trailings(POSITION_TYPE_BUY, TrailLowest, 0);
   myPosition.Trailings(POSITION_TYPE_SELL, TrailHighest, 0);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer() {
   Trail();
   myDate.Refresh();
   IsTradable = true;
   if(myDate.isFridayEnd() || myDate.isYearEnd()) {
      myPosition.CloseAllPositions(POSITION_TYPE_BUY);
      myPosition.CloseAllPositions(POSITION_TYPE_SELL);
      IsTradable = false;
   } else if(myTrade.isLowerBalance() || myTrade.isLowerMarginLevel()) {
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
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
