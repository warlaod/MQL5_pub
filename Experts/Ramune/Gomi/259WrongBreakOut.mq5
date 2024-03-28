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
MyPrice myPrice(Timeframe);
MyHistory myHistory(Timeframe);
MyOrder myOrder(myDate.BarTime*5);
CurrencyStrength CS(Timeframe, 1);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyFractal Fractal;
int OnInit() {
   MyUtils myutils(60 * 50);
   myutils.Init();
   Fractal.Create(_Symbol, Timeframe);
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
   myPosition.CheckTargetPriceProfitableForTrailings(POSITION_TYPE_BUY, myPrice.Lowest(0, 2));
   myPosition.CheckTargetPriceProfitableForTrailings(POSITION_TYPE_SELL, myPrice.Highest(0, 2));
   myPosition.Trailings(POSITION_TYPE_BUY, myPrice.Lowest(0, 2));
   myPosition.Trailings(POSITION_TYPE_SELL, myPrice.Highest(0, 2));
   if(!IsCurrentTradable || !IsTradable) return;

   Fractal.myRefresh();
   Fractal.SearchMiddle();


   myPrice.Refresh(3);
   if(Fractal.fractal(Middle, Up) < myPrice.At(1).high && Fractal.fractal(Middle, Up) > myPrice.At(2).high)
      setSignal(ORDER_TYPE_SELL);
   else if(Fractal.fractal(Middle, Low) > myPrice.At(1).low && Fractal.fractal(Middle, Low) < myPrice.At(2).low)
      setSignal(ORDER_TYPE_BUY);



   if(Signal == -1) return;

   myTrade.Refresh();
   myOrder.Refresh();
   double PriceUnit = pips;
   if(Signal == ORDER_TYPE_BUY) {
      if(myOrder.TotalEachOrders(ORDER_TYPE_BUY) < 1 && myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions) {
         myTrade.BuyStop(myPrice.At(1).high, myPrice.At(1).low, myPrice.At(1).high + 300 * pips);
      }
   } else if(Signal == ORDER_TYPE_SELL) {
      if(myOrder.TotalEachOrders(ORDER_TYPE_SELL) < 1 && myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions) {
         myTrade.SellStop(myPrice.At(1).low, myPrice.At(1).high, myPrice.At(1).low - 300 * pips);
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
