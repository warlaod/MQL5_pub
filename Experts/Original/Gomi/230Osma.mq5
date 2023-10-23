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
input mis_MarcosTMP timeFrame;
input int OsmaPeriod;
input int FastPeriod, SlowPeriod, SignalPeriod,SLPeriod;
ENUM_TIMEFRAMES Timeframe = defMarcoTiempo(timeFrame);
bool tradable = false;
double PriceToPips = PriceToPips();
double pips = PointToPips();
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
CiOsMA Osma;
int OnInit() {
   MyUtils myutils(60 * 1);
   myutils.Init();
   Osma.Create(_Symbol, Timeframe, FastPeriod, SlowPeriod, SignalPeriod, PRICE_CLOSE);

   if(FastPeriod >= SlowPeriod) return INIT_PARAMETERS_INCORRECT;
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

   Osma.Refresh();


   double BCount, SCount = 0;
   for(int i = OsmaPeriod; i > 0; i--) {
      if(Osma.Main(i + 1) > Osma.Main(i)) {
         if(i = 1) myPosition.CloseAllPositions(POSITION_TYPE_BUY);
         break;
      }
      BCount++;
   }
   for(int i = OsmaPeriod; i > 0; i--) {
      if(Osma.Main(i + 1) < Osma.Main(i)) {
         if(i = 1) myPosition.CloseAllPositions(POSITION_TYPE_SELL);
         break;
      }
      SCount++;
   }

   if(BCount == OsmaPeriod) myTrade.setSignal(ORDER_TYPE_BUY);
   if(SCount == OsmaPeriod) myTrade.setSignal(ORDER_TYPE_SELL);




   double PriceUnit = pips;
   if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions / 2 ) {
      myTrade.Buy(myPrice.Lowest(0,SLPeriod), myTrade.Ask + PriceUnit * TPCoef);
   }
   if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions / 2 ) {
      myTrade.Sell(myPrice.Highest(0,SLPeriod), myTrade.Bid - PriceUnit * TPCoef);
   }


}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer() {
   myPosition.Refresh();
   myTrade.Refresh();
   myOrder.Refresh();
   myDate.Refresh();


   tradable = true;


   if(myDate.isFridayEnd() || myDate.isYearEnd() || myDate.isMondayStart()) myTrade.istradable = false;
   myTrade.CheckBalance();
   myTrade.CheckMarginLevel();

   if(!myTrade.istradable) {
      myPosition.CloseAllPositions(POSITION_TYPE_BUY);
      myPosition.CloseAllPositions(POSITION_TYPE_SELL);
      tradable = false;
   }
   if(myOrder.wasOrderedInTheSameBar()) myTrade.istradable = false;
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

}


//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
