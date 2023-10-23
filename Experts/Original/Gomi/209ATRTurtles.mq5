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
#include <Original\MyChart.mqh>
#include <Indicators\TimeSeries.mqh>
#include <Indicators\Oscilators.mqh>
#include <Indicators\Trend.mqh>
#include <Indicators\BillWilliams.mqh>


input double SLCoef, TPCoef;
input int ATRPeriod, SLRange;
input ENUM_TIMEFRAMES Timeframe, LongTimeframe;
bool tradable = false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyTrade myTrade();
MyDate myDate();
MyPrice myPrice(Timeframe, 3), myLongPrice(LongTimeframe, 3);
MyOrder myOrder(Timeframe);
CurrencyStrength CS(Timeframe, 1);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CiATR ATR;
int OnInit() {
   MyUtils myutils(60 * 27);
   myutils.Init();

   ATR.Create(_Symbol, Timeframe, ATRPeriod);
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

   ATR.Refresh();
   myPrice.Refresh();
   myLongPrice.Refresh();
   

   double PriceUnit = ATR.Main(0);
   if(myLongPrice.At(1).high > myPrice.At(0).close) {
      if(myLongPrice.RosokuIsPlus(2) && myPrice.RosokuIsPlus(1)) {
         if(myLongPrice.RosokuLow(2) < myLongPrice.RosokuLow(1))
            myTrade.setSignal(ORDER_TYPE_BUY);
      }
   }
   if(myLongPrice.At(1).low < myPrice.At(0).close) {
      if(myLongPrice.RosokuIsPlus(2) && myPrice.RosokuIsPlus(1)) {
         if(myLongPrice.RosokuLow(2) < myLongPrice.RosokuLow(1))
            myTrade.setSignal(ORDER_TYPE_SELL);
      }
   }


   if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions / 2 ) {
      double SL = myPrice.Lowest(0, SLRange) - PriceUnit * SLCoef;
      myTrade.Buy(SL, myTrade.Ask + PriceUnit * TPCoef);
   }
   if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions / 2 ) {
      double SL = myPrice.Highest(0, SLRange) + PriceUnit * SLCoef;
      myTrade.Sell(SL, myTrade.Bid - PriceUnit * TPCoef);
   }


}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer() {
   myPosition.Refresh();
   myTrade.Refresh();

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
   myTrade.CheckSpread();
   myDate.isInTime("01:00", "07:00");
   if(myOrder.wasOrderedInTheSameBar()) myTrade.istradable = false;
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
