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
input mis_MarcosTMP timeFrame, slTimeframe;
input int EntryPeriod, SLPeriod;
input int ShortPeriod, MiddlePeriod, LongPeriod;
ENUM_TIMEFRAMES Timeframe = defMarcoTiempo(timeFrame);
ENUM_TIMEFRAMES SLTimeframe = defMarcoTiempo(slTimeframe);
double PriceToPips = PriceToPips();
double pips = PointToPips();
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyTrade myTrade();
MyDate myDate();
MyPrice myPrice(SLTimeframe, 3);
MyOrder myOrder(Timeframe);
CurrencyStrength CS(Timeframe, 1);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CiMA ShortMA, MiddleMA, LongMA;
int OnInit() {
   MyUtils myutils(60 * 50);
   myutils.Init();
   ShortMA.Create(_Symbol, Timeframe, ShortPeriod, 0, MODE_EMA, PRICE_CLOSE);
   MiddleMA.Create(_Symbol, Timeframe, ShortPeriod * MiddlePeriod, 0, MODE_EMA, PRICE_CLOSE);
   LongMA.Create(_Symbol, Timeframe, ShortPeriod * MiddlePeriod * LongPeriod, 0, MODE_EMA, PRICE_CLOSE);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool buySignal, sellSignal = false;
void OnTick() {
   Refresh();
   Check();

   //myPosition.CloseAllPositionsInMinute();
   if(!myTrade.isCurrentTradable || !myTrade.isTradable) return;

   ShortMA.Refresh();
   MiddleMA.Refresh();
   LongMA.Refresh();

   int BCount = 0;
   int SCount = 0;
   for(int i = 0; i <= EntryPeriod; i++) {
      if(i == EntryPeriod) {
         if(!isBetween(MiddleMA.Main(i), LongMA.Main(i), ShortMA.Main(i))) break;
      }
      if(isBetween(LongMA.Main(i), MiddleMA.Main(i), ShortMA.Main(i))) {
         BCount++;
      } else {
         if(i == 0)
            buySignal = false;
      }
   }

   for(int i = 0; i <= EntryPeriod; i++) {
      if(i == EntryPeriod) {
         if(!isBetween(ShortMA.Main(i), LongMA.Main(i), MiddleMA.Main(i))) break;
      }
      if(isBetween(ShortMA.Main(i), MiddleMA.Main(i), LongMA.Main(i))) {
         SCount++;
      } else {
         if(i == 0)
            sellSignal = false;
      }
   }

   if(BCount == EntryPeriod)
      buySignal = true;
   if(SCount == EntryPeriod)
      sellSignal = true;

   if(buySignal) myTrade.setSignal(ORDER_TYPE_BUY);
   if(sellSignal) myTrade.setSignal(ORDER_TYPE_SELL);

   myPrice.Refresh();

   double Lowest = myPrice.Lowest(0, SLPeriod);
   double Highest = myPrice.Highest(0, SLPeriod);
   if(myPrice.At(0).close < (Lowest + Highest) / 2 ) {
      if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions) {
         if(myPosition.isPositionInRange(MathAbs(LongMA.Main(0) - myTrade.Ask), POSITION_TYPE_BUY))return;
         myTrade.Buy(myPrice.Lowest(0, 2), LongMA.Main(0));
      }
   } else {
      if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions) {
         if(myPosition.isPositionInRange(MathAbs(LongMA.Main(0) - myTrade.Bid), POSITION_TYPE_SELL))return;
         myTrade.Sell(myPrice.Highest(0, 2), LongMA.Main(0));
      }
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

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
