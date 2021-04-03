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
input int IndPeriod, SLPeriod,TrailingTP;
input mis_MarcosTMP timeFrame, indTimeframe;
ENUM_TIMEFRAMES Timeframe = defMarcoTiempo(timeFrame);
ENUM_TIMEFRAMES IndTimeframe = defMarcoTiempo(indTimeframe);
input ENUM_MA_METHOD MAMethod;
input ENUM_APPLIED_PRICE AppliedPrice;
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
MyOrder myOrder(myDate.BarTime * 5);
//+------------------------------------------------------------------+
//|                                                                  |

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CiMA MA;
int  OnInit() {
   MyUtils myutils(60 * 50);
   myutils.Init();
   myTrade.SetExpertMagicNumber(MagicNumber);
   MA.Create(_Symbol, IndTimeframe, IndPeriod, 0, MAMethod, AppliedPrice);
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   IsCurrentTradable = true;
   Signal = -1;
   Check();

   //myPosition.CloseAllPositionsInMinute();
   myPosition.Refresh();
   myPosition.CheckTargetPriceProfitableForTrailings(POSITION_TYPE_BUY, myPrice.Lowest(0, SLPeriod));
   myPosition.CheckTargetPriceProfitableForTrailings(POSITION_TYPE_SELL, myPrice.Highest(0, SLPeriod));
   myPosition.Trailings(POSITION_TYPE_BUY,myPrice.Lowest(0,SLPeriod),TrailingTP*pips);
   myPosition.Trailings(POSITION_TYPE_SELL,myPrice.Highest(0,SLPeriod),TrailingTP*pips);
   if(!IsCurrentTradable || !IsTradable) return;
   myPrice.Refresh(12);

   MA.Refresh();
   double LastTrend = MA.Main(1) - MA.Main(2);
   double Trend = MA.Main(0) - MA.Main(1);
   if(LastTrend < 0 && Trend > 0)
      setSignal(ORDER_TYPE_BUY);
   if(LastTrend > 0 && Trend < 0)
      setSignal(ORDER_TYPE_SELL);


   if(Signal == -1) return;
   double PriceUnit = pips;
   myTrade.Refresh();
   myOrder.Refresh();
   if(Signal == ORDER_TYPE_BUY) {
      if(myOrder.TotalEachOrders(ORDER_TYPE_BUY) < 1 && myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions) {
         if(myPosition.isPositionInRange(POSITION_TYPE_BUY, MathAbs(myPrice.At(2).low - myTrade.Ask))) return;
         myTrade.BuyStop(myPrice.At(1).high, myPrice.At(2).low, myPrice.At(1).high + TPCoef * pips);
      }
   } else if(Signal == ORDER_TYPE_SELL) {
      if(myOrder.TotalEachOrders(ORDER_TYPE_SELL) < 1 && myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions) {
         if(myPosition.isPositionInRange(POSITION_TYPE_SELL, MathAbs(myPrice.At(2).high - myTrade.Bid))) return;
         myTrade.SellStop(myPrice.At(1).low, myPrice.At(2).high, myPrice.At(1).low - TPCoef * pips);
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
void Check() {
   myTrade.CheckSpread();
   myDate.Refresh();
   myHistory.Refresh();
   if(myDate.isMondayStart() == MONDAY) {
      IsCurrentTradable = false;
   } else if(myHistory.wasOrderedInTheSameBar()) IsCurrentTradable = false;
}
//+------------------------------------------------------------------+
