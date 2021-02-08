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
#include <Original\Optimization.mqh>
#include <Indicators\TimeSeries.mqh>
#include <Indicators\Oscilators.mqh>
#include <Indicators\Trend.mqh>
#include <Indicators\BillWilliams.mqh>
#include <Indicators\Volumes.mqh>
#include <Trade\PositionInfo.mqh>

input double SLCoef, TPCoef;
input mis_MarcosTMP timeFrame;
input int TrendPeriod;
ENUM_TIMEFRAMES Timeframe = defMarcoTiempo(timeFrame);
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
CiForce Force,ShortForce;
int OnInit() {
   MyUtils myutils(60 * 50);
   myutils.Init();
   Force.Create(_Symbol,Timeframe,13,MODE_EMA,VOLUME_TICK);
   ShortForce.Create(_Symbol,Timeframe,2,MODE_EMA,VOLUME_TICK);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   Refresh();
   Check();

   myPosition.CloseAllPositionsInMinute();
   if(!myTrade.isCurrentTradable || !myTrade.isTradable) return;
   
   ShortForce.Refresh();
   Force.Refresh();
   
   if(MathAbs(ShortForce.Main(0)) < 0.01) return
   
   if(isAllAbove(Force,0,TrendPeriod)){
      if(isTurnedToDown(ShortForce,0)) myTrade.setSignal(ORDER_TYPE_BUY);
   }
   
   if(isAllUnder(Force,0,TrendPeriod)){
      if(isTurnedToRise(ShortForce,0)) myTrade.setSignal(ORDER_TYPE_SELL);
   }


   double PriceUnit = pips;
   if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions) {
      myTrade.Buy(myPrice.Lowest(1,4) - PriceUnit*SLCoef, myPrice.Highest(0,4) + PriceUnit * TPCoef);
   }
   if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions) {
      myTrade.Sell(myPrice.Highest(1,4) + PriceUnit*SLCoef, myPrice.Lowest(0,4) - PriceUnit * TPCoef);
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
