//+------------------------------------------------------------------+
//|                                            1009ScalpFractals.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.01"
// 257HideSmashDay
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

 double TPCoef = 60;
 int IndPeriod = 25;
 int SLPeriod = 1;
 int OrderPeriod = 18;
 mis_MarcosTMP timeFrame = _H4;
 mis_MarcosTMP indTimeframe = _H1;
ENUM_TIMEFRAMES Timeframe = defMarcoTiempo(timeFrame);
ENUM_TIMEFRAMES IndTimeframe = defMarcoTiempo(indTimeframe);
 ENUM_MA_METHOD MAMethod = MODE_SMMA;
 ENUM_APPLIED_PRICE AppliedPrice = PRICE_CLOSE;
bool tradable = false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyTrade myTrade();
MySymbolAccount SA;
MyDate myDate(Timeframe);
MyPrice myPrice(Timeframe);
MyHistory myHistory(Timeframe);
MyOrder myOrder(myDate.BarTime * OrderPeriod);
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
   Check();
   myOrder.Refresh();

   //myPosition.CloseAllPositionsInMinute();
   myPosition.Refresh();
   myPosition.CheckTargetPriceProfitableForTrailings(POSITION_TYPE_BUY, myPrice.Lowest(0, SLPeriod));
   myPosition.CheckTargetPriceProfitableForTrailings(POSITION_TYPE_SELL, myPrice.Highest(0, SLPeriod));
   myPosition.Trailings(POSITION_TYPE_BUY, myPrice.Lowest(0, SLPeriod));
   myPosition.Trailings(POSITION_TYPE_SELL, myPrice.Highest(0, SLPeriod));
   if(!IsCurrentTradable || !IsTradable) return;
   Signal = -1;

   myPrice.Refresh(3);

   MA.Refresh();
   double LastTrend = MA.Main(1) - MA.Main(2);
   double Trend = MA.Main(0) - MA.Main(1);
   if(LastTrend < 0 && Trend > 0)
      setSignal(ORDER_TYPE_BUY);
   if(LastTrend > 0 && Trend < 0)
      setSignal(ORDER_TYPE_SELL);


   if(Signal == -1) return;
   myTrade.Refresh();
   if(Signal == ORDER_TYPE_BUY) {
      if(myOrder.TotalEachOrders(ORDER_TYPE_BUY) < 1 && myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions) {
         if(myPosition.isPositionInRange(POSITION_TYPE_BUY, MathAbs(myPrice.At(2).low - myTrade.Ask))) return;
         myTrade.BuyStop(myPrice.At(1).high, myPrice.At(2).low, myPrice.At(1).high + TPCoef * pipsToPrice);
      }
   } else if(Signal == ORDER_TYPE_SELL) {
      if(myOrder.TotalEachOrders(ORDER_TYPE_SELL) < 1 && myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions) {
         if(myPosition.isPositionInRange(POSITION_TYPE_SELL, MathAbs(myPrice.At(2).high - myTrade.Bid))) return;
         myTrade.SellStop(myPrice.At(1).low, myPrice.At(2).high, myPrice.At(1).low - TPCoef * pipsToPrice);
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
      myOrder.Refresh();
      myOrder.CloseAllOrders();
      Print("EA stopped trading because of lower balance or lower margin level  ");
      IsTradable = false;
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
   myDate.Refresh();
   myHistory.Refresh();
   if(myDate.isMondayStart() == MONDAY) {
      IsCurrentTradable = false;
   } else if(myHistory.wasOrderedInTheSameBar()) {
      IsCurrentTradable = false;
   } else if(SA.isOverSpread()) {
      IsCurrentTradable = false;
   }
}
//+------------------------------------------------------------------+
