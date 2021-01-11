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
#include <Indicators\TimeSeries.mqh>
#include <Indicators\Oscilators.mqh>
#include <Indicators\Trend.mqh>
#include <Indicators\BillWilliams.mqh>
#include <Indicators\Volumes.mqh>

input double SLCoef, TPCoef;
input ENUM_TIMEFRAMES Timeframe;
input int TrendRange;
bool tradable = false;
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
CiForce Force;
CiMA MALong, MAShort;
int OnInit() {
   MyUtils myutils(60 * 27);
   myutils.Init();

   Force.Create(_Symbol, Timeframe, 48, MODE_EMA, VOLUME_TICK);
   MAShort.Create(_Symbol, Timeframe, 3, 0, MODE_EMA, PRICE_CLOSE);
   MALong.Create(_Symbol, Timeframe, 12, 0, MODE_EMA, PRICE_CLOSE);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   Refresh();
   Check();

   Force.Refresh();
   MAShort.Refresh();
   MALong.Refresh();
   if(isGoldenCross(MAShort.Main(2), MALong.Main(2), MAShort.Main(1), MALong.Main(1)))
      myPosition.CloseAllPositions(POSITION_TYPE_SELL);
   if(isDeadCross(MAShort.Main(2), MALong.Main(2), MAShort.Main(1), MALong.Main(1)))
      myPosition.CloseAllPositions(POSITION_TYPE_BUY);

   myPosition.CloseAllPositionsInMinute();
   if(!myTrade.istradable || !tradable) return;




   CArrayDouble MADiff, ForceIndexes;
   for(int i = 0; i <= 2; i++) {
      MADiff.Add((MathAbs(MALong.Main(i) - MAShort.Main(i))));
   }

   if(MADiff.At(1) < MADiff.At(2)) return;
   for(int i = 0; i <= 2; i++) {
      if(MathAbs(Force.Main(i)) < 0.1) return;
   }
   
   double LongTrend = MALong.Main(1) - MALong.Main(TrendRange);
   double ShortTrend = MAShort.Main(1) - MAShort.Main(TrendRange);
   
   if(isGoldenCross(MAShort.Main(3), MALong.Main(3), MAShort.Main(2), MALong.Main(2))) {
      if(LongTrend > 0 && ShortTrend > 0) {
         myTrade.setSignal(ORDER_TYPE_BUY);
      }
   }

   if(isDeadCross(MAShort.Main(3), MALong.Main(3), MAShort.Main(2), MALong.Main(2))) {
      if(LongTrend < 0 && ShortTrend < 0) {
         myTrade.setSignal(ORDER_TYPE_SELL);
      }
   }




   double PriceUnit = 10 * _Point;
   if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions / 2 ) {
   myTrade.Buy(myTrade.Ask - PriceUnit * SLCoef, myTrade.Ask + PriceUnit * TPCoef);
   }
   if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions / 2 ) {
   myTrade.Sell(myTrade.Bid + PriceUnit * SLCoef, myTrade.Bid - PriceUnit * TPCoef);
   }


}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer() {
   myPosition.Refresh();
   myTrade.Refresh();
   myDate.Refresh();

   tradable = true;

   if(myDate.isFridayEnd() || myDate.isYearEnd()) myTrade.istradable = false;
   myTrade.CheckBalance();
   myTrade.CheckMarginLevel();

   if(!myTrade.istradable) {
      myPosition.CloseAllPositions(POSITION_TYPE_BUY);
      myPosition.CloseAllPositions(POSITION_TYPE_SELL);
      tradable = false;
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
double OnTester() {
   MyTest myTest;
   double result =  myTest.PROM();
   return  result;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Refresh() {
   myPosition.Refresh();
   myTrade.Refresh();
   myOrder.Refresh();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Check() {
//myTrade.CheckSpread();
   //if(!myDate.isInTime("16:00", "23:00")) myTrade.istradable = false;
   if(myOrder.wasOrderedInTheSameBar()) myTrade.istradable = false;
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
