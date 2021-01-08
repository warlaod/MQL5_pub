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
input int PriceRange;
bool tradable = false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyTrade myTrade();
MyDate myDate();
MyPrice myPrice(Timeframe, PriceRange);
MyOrder myOrder(Timeframe);
CurrencyStrength CS(Timeframe, 1);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CiOBV OBV;
CiBands Band;
int OnInit() {
   MyUtils myutils(60 * 27);
   myutils.Init();
   OBV.Create(_Symbol, Timeframe, VOLUME_TICK);
   Band.Create(_Symbol, Timeframe, 20, 0, 2, PRICE_CLOSE);
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

   OBV.Refresh();
   myPrice.Refresh();
   Band.Refresh();

   CArrayDouble OBVArray;
   for(int i = 5; i < PriceRange; i++) {
      OBVArray.Add(OBV.Main(i));
   }

   int max = OBVArray.Maximum(1, PriceRange);
   int min = OBVArray.Minimum(1, PriceRange);

   if(OBVArray.At(max) < OBV.Main(0)) {
      if(myPrice.At(1).high > Band.Upper(1)) myTrade.setSignal(ORDER_TYPE_BUY);
   }

   if(OBVArray.At(min) > OBV.Main(0)) {
      if(myPrice.At(1).low < Band.Lower(1))  myTrade.setSignal(ORDER_TYPE_SELL);
   }

   double PriceUnit = Band.Upper(0) - Band.Base(0);
   if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions / 2 )
      myTrade.Buy(Band.Lower(0), myTrade.Ask + PriceUnit * TPCoef);
   if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions / 2 )
      myTrade.Sell(Band.Upper(0), myTrade.Bid - PriceUnit * TPCoef);


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
   //myDate.isInTime("01:00", "07:00");
   if(myOrder.wasOrderedInTheSameBar()) myTrade.istradable = false;
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
