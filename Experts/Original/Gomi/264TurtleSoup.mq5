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
input int TrailPeriod,TurtlePeriod,StartPeriod;
input int EntryCri,SLCri;
input mis_MarcosTMP timeFrame;
ENUM_TIMEFRAMES Timeframe = defMarcoTiempo(timeFrame);
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
MyOrder myOrder(myDate.BarTime * 7);
CurrencyStrength CS(Timeframe, 1);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   MyUtils myutils(60 * 1);
   myutils.Init();
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
   double PriceUnit = pips;

   double Highest = myPrice.Highest(2, TurtlePeriod);
   double Lowest = myPrice.Lowest(2, TurtlePeriod);

   myPrice.Refresh(2);
   if(Highest == myPrice.Highest(StartPeriod, TurtlePeriod)) {
      if(myPrice.At(1).high > Highest)
         setSignal(ORDER_TYPE_SELL);
   } else if(Lowest == myPrice.Lowest(StartPeriod, TurtlePeriod)) {
      if(myPrice.At(1).low < Lowest)
         setSignal(ORDER_TYPE_BUY);
   }

   if(Signal == -1) return;

   myTrade.Refresh();
   myOrder.Refresh();
   if(Signal == ORDER_TYPE_BUY) {
      if(myOrder.TotalEachOrders(ORDER_TYPE_BUY) < 1 && myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions) {
         myTrade.BuyStop(Lowest + EntryCri * pips, myPrice.At(1).low - SLCri * pips, myTrade.Ask + PriceUnit * TPCoef);
      }
   } else if(Signal == ORDER_TYPE_SELL) {
      if(myOrder.TotalEachOrders(ORDER_TYPE_SELL) < 1 && myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions) {
         myTrade.SellStop(Highest - EntryCri * pips, myPrice.At(1).high + SLCri * pips, myTrade.Bid - PriceUnit * TPCoef);
      }
   }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer() {
   myPosition.Refresh();
   double TrailLowest = myPrice.Lowest(1, TrailPeriod);
   double TrailHighest = myPrice.Highest(1, TrailPeriod);
   myPosition.CheckTargetPriceProfitableForTrailings(POSITION_TYPE_BUY, TrailLowest);
   myPosition.CheckTargetPriceProfitableForTrailings(POSITION_TYPE_SELL, TrailHighest);
   myPosition.Trailings(POSITION_TYPE_BUY, TrailLowest, 100000);
   myPosition.Trailings(POSITION_TYPE_SELL, TrailHighest, 0);

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
