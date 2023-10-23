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
input int OBVRange;
bool tradable = false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyTrade myTrade();
MyDate myDate();
MyPrice myPrice(Timeframe, OBVRange);
MyOrder myOrder(Timeframe);
CurrencyStrength CS(Timeframe, 1);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CiOBV OBV;
CiMA MALong, MAShort;
int OnInit() {
   MyUtils myutils(60 * 27);
   myutils.Init();
   OBV.Create(_Symbol, Timeframe, VOLUME_TICK);
   MALong.Create(_Symbol, Timeframe, 50, 0, MODE_EMA, PRICE_CLOSE);
   MAShort.Create(_Symbol, Timeframe, 10, 0, MODE_EMA, PRICE_CLOSE);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   Refresh();
   Check();

   myPosition.CloseAllPositionsInMinute();
   if(!myTrade.istradable || !tradable) return;

   OBV.Refresh();
   myPrice.Refresh();
   MALong.Refresh();
   MAShort.Refresh();

   double OBVTrend = OBV.Main(0) - OBV.Main(OBVRange);
   double OldOBVTrend = OBV.Main(1) - OBV.Main(OBVRange + 1);

   if(MALong.Main(0) > MAShort.Main(0)) {
      if(isTurnedToRise(OldOBVTrend, OBVTrend)) myTrade.setSignal(ORDER_TYPE_BUY);
   }

   if(MALong.Main(0) < MAShort.Main(0)) {
      if(isTurnedToDown(OldOBVTrend, OBVTrend)) myTrade.setSignal(ORDER_TYPE_SELL);
   }

   double PriceUnit = 10 * _Point;
   if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions / 2 )
      myTrade.Buy(myPrice.Lowest(0, 2), MALong.Main(0));
   if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions / 2 )
      myTrade.Sell(myPrice.Highest(0, 2), MALong.Main(0));


}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer() {
   myPosition.Refresh();
   myTrade.Refresh();
   myDate.Refresh();

   tradable = true;

   if(myDate.isFridayEnd() || myDate.isYearEnd())
      myTrade.istradable = false;
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
   //if(!myDate.isInTime("15:00", "17:00")) myTrade.istradable = false;
   if(!myDate.isInTime("01:00", "05:00")) myTrade.istradable = false;
   if(myOrder.wasOrderedInTheSameBar()) myTrade.istradable = false;
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
