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

input double distance;
input mis_MarcosTMP timeFrame, slTimeframe, trailTimeframe;
ENUM_TIMEFRAMES Timeframe = defMarcoTiempo(timeFrame);
ENUM_TIMEFRAMES SLTimeframe = defMarcoTiempo(slTimeframe);
ENUM_TIMEFRAMES TrailTimeframe = defMarcoTiempo(trailTimeframe);
bool tradable = false;
double PriceToPips = PriceToPips();
double pips = PointToPips();

input int SLPeriod, TrailPeriod;
input int PriceCount;
input double CoreCri, HalfStopCri;
input int ADXMainCri, ADXSubCri;
input double slHalf;
double SLHalf = MathPow(2, slHalf)*pips;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyTrade myTrade();
MyDate myDate(Timeframe);
MyPrice myPrice(PERIOD_MN1), mySLPrice(SLTimeframe), myTrailPrice(TrailTimeframe);
MyHistory myHistory(Timeframe);
MyOrder myOrder(myDate.BarTime);
CurrencyStrength CS(Timeframe, 1);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CiADX ADX;
CiATR ATR;
int OnInit() {
   MyUtils myutils(60 * 1);
   myutils.Init();
   ADX.Create(_Symbol, Timeframe,14);
   return(INIT_SUCCEEDED);
}


double Distance = MathPow(2,distance);
void OnTimer() {
   Trail();
   Check();
   IsCurrentTradable = true;
   Signal = NULL;

   ADX.Refresh();
   if(ADX.Main(0) < ADXMainCri) return;
   if(!isBetween(ADX.Main(0), ADX.Main(1), ADX.Main(2))) return;

   myPrice.Refresh(1);
   double Lowest = myPrice.Lowest(0, PriceCount);
   double Highest = myPrice.Highest(0, PriceCount);
   double HLGap = Highest - Lowest;
   double Current = myPrice.At(0).close;
   double perB = (Current - Lowest) / (Highest - Lowest);

   if(perB > 1 - HalfStopCri || perB < HalfStopCri) return;
   double BuySL, SellSL;

   myTrade.Refresh();
   if(perB < 0.5 - CoreCri) {
      if(isAbleToBuy()) {
         BuySL = Lowest - SLHalf;
         myTrade.ForceBuy(BuySL, 1000000);
      }
   } else if(perB > 0.5 + CoreCri) {
      if(isAbleToSell()) {
         SellSL = Highest + SLHalf;
         myTrade.ForceSell(SellSL, 0);
      }
   } else {
      if(isBetween(0.5, perB, 0.5 - CoreCri) && isAbleToBuy())
         myTrade.ForceBuy(mySLPrice.Lowest(1,SLPeriod), 1000000);
      else if(isBetween(0.5 + CoreCri, perB, 0.5) && isAbleToSell())
         myTrade.ForceSell(mySLPrice.Highest(1,SLPeriod), 0);
   }
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isAbleToBuy() {
   if(ADX.Plus(0) > ADXSubCri && ADX.Plus(0) > ADX.Minus(0)) {
      if(isBetween(ADX.Plus(0), ADX.Plus(1), ADX.Plus(2))) {
         if(!myPosition.isPositionInRange(POSITION_TYPE_BUY, Distance))
            return true;
      }
   }
   return false;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isAbleToSell() {
   if(ADX.Minus(0) > ADXSubCri && ADX.Minus(0) > ADX.Plus(0)) {
      if(isBetween(ADX.Minus(0), ADX.Minus(1), ADX.Minus(2))) {
         if(!myPosition.isPositionInRange(POSITION_TYPE_SELL, Distance))
            return true;
      }
   }
   return false;
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
   if(myTrade.isLowerBalance() || myTrade.isLowerMarginLevel()) {
      myPosition.CloseAllPositions();
      Print("EA stopped because of lower balance or lower margin level");
      ExpertRemove();
   }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void  Trail() {
   myPosition.Refresh();
   myPosition.CheckTargetPriceProfitableForTrailings(POSITION_TYPE_BUY, myTrailPrice.Lowest(1, SLPeriod));
   myPosition.CheckTargetPriceProfitableForTrailings(POSITION_TYPE_SELL, myTrailPrice.Highest(1, SLPeriod));
   myPosition.Trailings(POSITION_TYPE_BUY, myPrice.Lowest(1, SLPeriod), 0);
   myPosition.Trailings(POSITION_TYPE_SELL, myPrice.Highest(1, SLPeriod), 0);
}
//+------------------------------------------------------------------+
