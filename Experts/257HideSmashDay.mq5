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
MyPrice myPrice(Timeframe, 3);
MyHistory myHistory(Timeframe);
MyOrder myOrder(myDate.BarTime * 7);
CurrencyStrength CS(Timeframe, 1);
//+------------------------------------------------------------------+
//|                                                                  |

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   MyUtils myutils(60 * 50);
   myutils.Init();
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   Refresh();
   Check();

   //myPosition.CloseAllPositionsInMinute();

   myPosition.CheckTargetPriceProfitableForTrailings(POSITION_TYPE_BUY, myPrice.Lowest(0, 2));
   myPosition.CheckTargetPriceProfitableForTrailings(POSITION_TYPE_SELL, myPrice.Highest(0, 2));

   if(!myTrade.isCurrentTradable || !myTrade.isTradable) return;
   myPrice.Refresh();
   myOrder.Refresh();

   if((myPrice.At(1).high - myPrice.At(1).low) == 0) return;

   double perBCandle = (myPrice.At(1).close - myPrice.At(1).low) / (myPrice.At(1).high - myPrice.At(1).low);

   if(myPrice.RosokuIsPlus(2) && perBCandle < 0.25) {
      if(myPrice.At(2).low < myPrice.At(1).low && myPrice.At(2).high < myPrice.At(1).high)
         myTrade.setSignal(ORDER_TYPE_BUY);
   } else  if(!myPrice.RosokuIsPlus(2) && perBCandle > 0.75) {
      if(myPrice.At(2).high > myPrice.At(1).high && myPrice.At(2).low > myPrice.At(1).low)
         myTrade.setSignal(ORDER_TYPE_SELL);
   }
   double PriceUnit = pips;
   if(myOrder.TotalEachOrders(ORDER_TYPE_BUY) < positions && myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions) {
      myTrade.BuyStop(myPrice.At(1).high, myPrice.At(2).low, myPrice.At(1).high + 100 * pips);
   } else if(myOrder.TotalEachOrders(ORDER_TYPE_SELL) < positions && myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions) {
       int aadw = myOrder.TotalEachOrders(ORDER_TYPE_SELL);
       int dwa  = myPosition.TotalEachPositions(POSITION_TYPE_SELL);
      myTrade.SellStop(myPrice.At(1).low, myPrice.At(2).high, myPrice.At(1).low - 100 * pips);
   }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer() {
   myPosition.Refresh();
   myTrade.Refresh();
   myDate.Refresh();
   myTrade.isTradable = true;
   if(myDate.isFridayEnd() || myDate.isYearEnd()) {
      myPosition.CloseAllPositions(POSITION_TYPE_BUY);
      myPosition.CloseAllPositions(POSITION_TYPE_SELL);
      myTrade.isTradable = false;
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
   myHistory.Refresh();
   if(myDate.isMondayStart()) myTrade.isCurrentTradable = false;
   else if(myHistory.wasOrderedInTheSameBar()) myTrade.isCurrentTradable = false;
}
//+------------------------------------------------------------------+
