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

mis_MarcosTMP timeFrame = _H1;
mis_MarcosTMP atrTimeframe = _H1;
ENUM_TIMEFRAMES Timeframe = defMarcoTiempo(timeFrame);
ENUM_TIMEFRAMES ATRTimeframe = defMarcoTiempo(atrTimeframe);
double PriceToPips = PriceToPips();
double pips = PointToPips();

 int ADXPeriod = 18;
 int PriceCount = 24;
 double CoreCri = 0.12;
 double HalfStopCri =0.08;
 int ADXMainCri = 24;
 int ADXSubCri = 24;
 double slHalf = 2.25;
 double slCore = 6.75;
 double CoreTP = 1.4;
 double HalfTP = 4.8;
double SLHalf = MathPow(2, slHalf);
double SLCore = MathPow(2, slCore);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyTrade myTrade();
MyDate myDate(Timeframe);
MyPrice myPrice(PERIOD_MN1);
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
   ADX.Create(_Symbol, Timeframe, ADXPeriod);
   ATR.Create(_Symbol, ATRTimeframe, 14);
   return(INIT_SUCCEEDED);
}


double PriceUnit;
void OnTimer() {
   myPosition.Refresh();
   Check();
   IsCurrentTradable = true;
   Signal = NULL;
   
   ATR.Refresh();
   PriceUnit = ATR.Main(0);
   
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
   double bottom, top,TP;
   
   myTrade.Refresh();
   if(perB < 0.5 - CoreCri) {
      if(isAbleToBuy()) {
         TP = PriceUnit * HalfTP;
         bottom = Lowest - SLHalf * PriceUnit;
         myTrade.ForceBuy(bottom, myTrade.Ask + TP);
      }
   } else if(perB > 0.5 + CoreCri) {
      if(isAbleToSell()) {
         TP = PriceUnit * HalfTP;
         top = Highest + SLHalf * PriceUnit;
         myTrade.ForceSell(top, myTrade.Bid - TP);
      }
   } else {
      top = Highest - HLGap * CoreCri  + SLCore * PriceUnit;
      bottom = Lowest + HLGap * CoreCri - SLCore * PriceUnit;
      TP = PriceUnit * CoreTP;
      if(isBetween(0.5, perB, 0.5 - CoreCri) && isAbleToBuy())
         myTrade.ForceBuy(bottom, myTrade.Ask + TP);
      else if(isBetween(0.5 + CoreCri, perB, 0.5) && isAbleToSell())
         myTrade.ForceSell(top, myTrade.Bid - TP);
   }
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isAbleToBuy() {
   if(ADX.Plus(0) > ADXSubCri && ADX.Plus(0) > ADX.Minus(0)) {
      if(isBetween(ADX.Plus(0), ADX.Plus(1), ADX.Plus(2))) {
         if(!myPosition.isPositionInRange(POSITION_TYPE_BUY, PriceUnit))
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
         if(!myPosition.isPositionInRange(POSITION_TYPE_SELL, PriceUnit))
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
void Refresh() {
   myPosition.Refresh();
   myTrade.Refresh();
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Check() {
   if(myTrade.isLowerBalance() || myTrade.isLowerMarginLevel()) {
      myPosition.CloseAllPositions(POSITION_TYPE_BUY);
      myPosition.CloseAllPositions(POSITION_TYPE_SELL);
      Print("EA stopped because of lower balance or lower margin level");
      ExpertRemove();
   }
}
//+------------------------------------------------------------------+
