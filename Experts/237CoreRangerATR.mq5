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
input int PricePeriod;
input mis_MarcosTMP timeFrame, shortTimeframe;
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
CurrencyStrength CS(Timeframe, 1);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CiATR ATR;
CiOsMA OsmaLong, OsmaShort;
int OnInit() {
   MyUtils myutils(60 * 1);
   myutils.Init();
   ATR.Create(_Symbol, PERIOD_W1, 2);
   OsmaLong.Create(_Symbol, Timeframe, 12, 26, 9, PRICE_WEIGHTED);
   OsmaShort.Create(_Symbol, ShortTimeframe, 12, 26, 9, PRICE_WEIGHTED);
   
   if(Timeframe <= ShortTimeframe) return INIT_PARAMETERS_INCORRECT;
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {


}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer() {
   myPosition.Refresh();
   myTrade.Refresh();
   myDate.Refresh();

   if(myTrade.isLowerBalance() || myTrade.isLowerMarginLevel()) {
      myPosition.CloseAllPositions(POSITION_TYPE_BUY);
      myPosition.CloseAllPositions(POSITION_TYPE_SELL);
      myTrade.isTradable = false;
   } else {
      myTrade.isTradable = true;
   }

   {
      Refresh();
      Check();

      //myPosition.CloseAllPositionsInMinute();
      if(!myTrade.isCurrentTradable || !myTrade.isTradable) return;

      myPrice.Refresh();
      ATR.Refresh();
      OsmaLong.Refresh();
      OsmaShort.Refresh();

      double Highest = myPrice.Highest(0, PricePeriod);
      double Lowest = myPrice.Lowest(0, PricePeriod);
      double perB = (myPrice.At(0).close - Lowest) / (Highest - Lowest);

      if(perB > 0.5) {
         if(OsmaLong.Main(1) > OsmaLong.Main(0) && OsmaShort.Main(2) < OsmaShort.Main(1) )
            myTrade.setSignal(ORDER_TYPE_SELL);
      }

      if(perB < 0.5) {
         if(OsmaLong.Main(1) < OsmaLong.Main(0) && OsmaShort.Main(2) > OsmaShort.Main(1) )
            myTrade.setSignal(ORDER_TYPE_BUY);
      }

      double PriceUnit = ATR.Main(0);
      if(myPosition.isPositionInRange(POSITION_TYPE_BUY, PriceUnit * TPCoef)) return;
      myTrade.Buy(0.01, myTrade.Ask + PriceUnit * TPCoef);

      if(myPosition.isPositionInRange(POSITION_TYPE_SELL, PriceUnit * TPCoef)) return;
      myTrade.Sell(5, myTrade.Bid - PriceUnit * TPCoef);
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
   myTrade.CheckSpread();
}
//+------------------------------------------------------------------+
