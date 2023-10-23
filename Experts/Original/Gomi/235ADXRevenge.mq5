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
input mis_MarcosTMP timeFrame, longTimeframe;
ENUM_TIMEFRAMES Timeframe = defMarcoTiempo(timeFrame);
ENUM_TIMEFRAMES LongTimeframe = defMarcoTiempo(longTimeframe);
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
CiADX ADX;
CiBands Band;
int OnInit() {
   MyUtils myutils(60 * 50);
   myutils.Init();
   if(LongTimeframe <= Timeframe) return INIT_PARAMETERS_INCORRECT;
   ADX.Create(_Symbol, LongTimeframe, 14);
   Band.Create(_Symbol, Timeframe, 20, 0, 2, PRICE_CLOSE);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   Refresh();
   Check();

   myPosition.CloseAllPositionsInMinute();
   if(!myTrade.isCurrentTradable || !myTrade.isTradable) return;

   Band.Refresh();
   ADX.Refresh();
   myPrice.Refresh();

   if(ADX.Main(0) < 20) return;
   if(!isBetween(ADX.Main(0), ADX.Main(1), ADX.Main(2))) return;

   if(ADX.Plus(0) > 20) {
      if(Band.Lower(2) > myPrice.At(2).low && myPrice.At(2).low < myPrice.At(1).low)
         myTrade.setSignal(ORDER_TYPE_BUY);
   }

   if(ADX.Minus(0) > 20) {
      if(Band.Upper(2) < myPrice.At(2).high && myPrice.At(2).high > myPrice.At(1).high)
         myTrade.setSignal(ORDER_TYPE_SELL);
   }


   double PriceUnit = pips;
   if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions) {
      myTrade.Buy(Band.Lower(0) - PriceUnit * SLCoef, Band.Upper(0) + PriceUnit * TPCoef);
   }
   if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions) {
      myTrade.Sell(Band.Upper(0) + PriceUnit * SLCoef, Band.Lower(0) - PriceUnit * TPCoef);
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
