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
#include <Original\MySymbolAccount.mqh>
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
input mis_MarcosTMP timeFrame, timeFrame2, timeFrame3;
ENUM_TIMEFRAMES Timeframe = defMarcoTiempo(timeFrame);
ENUM_TIMEFRAMES Timeframe2 = defMarcoTiempo(timeFrame2);
ENUM_TIMEFRAMES Timeframe3 = defMarcoTiempo(timeFrame3);
bool tradable = false;
double PriceToPips = PriceToPips();
double pips = PointToPips();
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyTrade myTrade();
MySymbolAccount SymbolAccount;
MyDate myDate(Timeframe);
MyPrice myPrice(Timeframe);
MyHistory myHistory(Timeframe);
MyOrder myOrder(myDate.BarTime * 5);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   MyUtils myutils(60 * 50);
   myutils.Init();
   myTrade.SetExpertMagicNumber(MagicNumber);
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

   setSignal(ORDER_TYPE_BUY);

   if(Signal == -1) return;

   myTrade.Refresh();
   myPosition.Refresh();
   myOrder.Refresh();
   if(Signal == ORDER_TYPE_BUY) {
      if(myOrder.TotalEachOrders(ORDER_TYPE_BUY) < 1 && myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions) {
         myTrade.Buy(myTrade.Ask - PriceUnit * SLCoef, myTrade.Ask + PriceUnit * TPCoef);
      }
   } else if(Signal == ORDER_TYPE_SELL) {
      if(myOrder.TotalEachOrders(ORDER_TYPE_SELL) < 1 && myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions) {
         myTrade.Sell(myTrade.Bid + PriceUnit * SLCoef, myTrade.Bid - PriceUnit * TPCoef);
      }
   }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Check() {
   myDate.Refresh();
   myHistory.Refresh();
   if(myDate.isMondayStart() == MONDAY) {
      IsCurrentTradable = false;
   } else if(myHistory.wasOrderedInTheSameBar()) {
      IsCurrentTradable = false;
   }// else if(SymbolAccount.isOverSpread()) IsCurrentTradable = false;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Trail() {
   myPosition.Refresh();
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer() {
   myDate.Refresh();
   IsTradable = true;
   if(myDate.isFridayEnd() || myDate.isYearEnd()) {
      myPosition.Refresh();
      myOrder.Refresh();
      myPosition.CloseAllPositions();
      myOrder.CloseAllOrders();
      IsTradable = false;
   } else if(myTrade.isLowerBalance() || myTrade.isLowerMarginLevel()) {
      myPosition.Refresh();
      myOrder.Refresh();
      myPosition.CloseAllPositions();
      myOrder.CloseAllOrders();
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
