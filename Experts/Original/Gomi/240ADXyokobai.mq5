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
input mis_MarcosTMP timeFrame,shortTimeframe;
input int ATRPeriod, ADXPeriod,ATRArrayPeriod,PricePeriod
;
input double ATRCri;
ENUM_TIMEFRAMES Timeframe = defMarcoTiempo(timeFrame);
ENUM_TIMEFRAMES ShortTimeframe = defMarcoTiempo(shortTimeframe);
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
CiATR ATR;
CArrayDouble ATRArray;
int OnInit() {
   MyUtils myutils(60 * 50);
   myutils.Init();
   ADX.Create(_Symbol, Timeframe, ADXPeriod);
   ATR.Create(_Symbol, ShortTimeframe, ATRPeriod);
   
   if(Timeframe <= ShortTimeframe) return INIT_PARAMETERS_INCORRECT;
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   Refresh();
   Check();

   //myPosition.CloseAllPositionsInMinute();
   if(!myTrade.isCurrentTradable || !myTrade.isTradable) return;

   ADX.Refresh();
   ATR.Refresh();
   myPrice.Refresh();

   if(ADX.Main(0) > 20)
      return;
   
   for(int i=0;i<ATRArrayPeriod;i++)
     {
      ATRArray.Add(ATR.Main(i));
     }
   if(ATRArray.At(ATRArray.Minimum(0,ATRArrayPeriod)) /ATR.Main(0) > ATRCri)
      return;

   double Highest = myPrice.Highest(0,  ADXPeriod);
   double Lowest = myPrice.Lowest(0, ADXPeriod);
   double perB = (myPrice.At(0).close - Lowest) / (Highest - Lowest);

   if(isBetween(1, perB, 0.8)) {
      myTrade.setSignal(ORDER_TYPE_SELL);
   }

   if(isBetween(0.2, perB, 0)) {
      myTrade.setSignal(ORDER_TYPE_BUY);
   }


   double PriceUnit = pips;
   if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions) {
      myTrade.Buy(myTrade.Ask - PriceUnit * SLCoef, myTrade.Ask + PriceUnit * TPCoef);
   }
   if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions) {
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
