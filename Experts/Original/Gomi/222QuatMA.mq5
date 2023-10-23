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
CiMA MALong, MAMiddle, MAShort, MAvShort;
int OnInit() {
   MyUtils myutils(60 * 27);
   myutils.Init();

   MALong.Create(_Symbol, Timeframe, 250, 0, MODE_EMA, PRICE_CLOSE);
   MAMiddle.Create(_Symbol, Timeframe, 50, 0, MODE_EMA, PRICE_CLOSE);
   MAShort.Create(_Symbol, Timeframe, 10, 0, MODE_EMA, PRICE_CLOSE);
   MAvShort.Create(_Symbol, Timeframe, 2, 0, MODE_EMA, PRICE_CLOSE);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   Refresh();
   Check();

   //myPosition.CloseAllPositionsInMinute();
   if(!myTrade.istradable || !tradable) return;

   MALong.Refresh();
   MAMiddle.Refresh();
   MAShort.Refresh();
   MAvShort.Refresh();

   if(isBetween(MALong.Main(0), MAMiddle.Main(0), MAShort.Main(0)) && MAShort.Main(0) > MAvShort.Main(0))
      myTrade.setSignal(ORDER_TYPE_SELL);

   if(isBetween(MAShort.Main(0), MAMiddle.Main(0), MALong.Main(0)) && MAShort.Main(0) < MAvShort.Main(0))
      myTrade.setSignal(ORDER_TYPE_BUY);


   double PriceUnit = 10 * _Point;
   if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions / 2 ) {
      myTrade.Buy(myPrice.Lowest(0, 20), myTrade.Ask + PriceUnit * TPCoef);
   }
   if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions / 2 ) {
      myTrade.Sell(myPrice.Highest(0, 20), myTrade.Bid - PriceUnit * TPCoef);
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
   //if(!myDate.isInTime("01:00", "07:00")) myTrade.istradable = false;
   if(myOrder.wasOrderedInTheSameBar()) myTrade.istradable = false;
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
