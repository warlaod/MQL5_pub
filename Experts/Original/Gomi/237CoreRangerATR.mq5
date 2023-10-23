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

input double TPCoefRange, TPCoefHalf;
input int PricePeriod, ATRPeriod;
input double CoreRange, UntradeRange;
input mis_MarcosTMP timeFrame, shortTimeframe, atrTimeframe;
ENUM_TIMEFRAMES Timeframe = defMarcoTiempo(timeFrame);
ENUM_TIMEFRAMES ShortTimeframe = defMarcoTiempo(shortTimeframe);
ENUM_TIMEFRAMES ATRTimeframe = defMarcoTiempo(atrTimeframe);
bool tradable = false;
double PriceToPips = PriceToPips();
double pips = PointToPips();
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyTrade myTrade();
MyDate myDate();
MyPrice myPrice(PERIOD_MN1, 3);
CurrencyStrength CS(Timeframe, 1);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CiATR ATR;
CiOsMA Osma;
int OnInit() {
   MyUtils myutils(60 * 5);
   myutils.Init();
   ATR.Create(_Symbol, ATRTimeframe, ATRPeriod);
   Osma.Create(_Symbol, Timeframe, 12, 26, 9, PRICE_TYPICAL);

   if(Timeframe <= ShortTimeframe) return INIT_PARAMETERS_INCORRECT;
   if(CoreRange + UntradeRange >= 0.5) return INIT_PARAMETERS_INCORRECT;
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
      Osma.Refresh();

      double Highest = myPrice.Highest(0, PricePeriod);
      double Lowest = myPrice.Lowest(0, PricePeriod);
      double perB = (myPrice.At(0).close - Lowest) / (Highest - Lowest);
      double PriceUnit = ATR.Main(0);

      if(perB < UntradeRange || perB > 1 - UntradeRange) return;


      if(Osma.Main(1) > 0 && Osma.Main(1) < Osma.Main(0)) {
         if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions)
            myTrade.setSignal(ORDER_TYPE_BUY);
      }

      if(Osma.Main(1) < 0 && Osma.Main(1) > Osma.Main(0)) {
         if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions)
            myTrade.setSignal(ORDER_TYPE_SELL);
      }

      if(isBetween(0.5 + CoreRange, perB, 0.5 - CoreRange)) {
         PriceUnit = PriceUnit * TPCoefRange;
         if(!myPosition.isPositionInRange(POSITION_TYPE_BUY, PriceUnit)) {
            myTrade.Buy(0.01, myTrade.Ask + PriceUnit * TPCoefRange);
         } else if(!myPosition.isPositionInRange(POSITION_TYPE_SELL, PriceUnit)) {
            myTrade.Sell(5, myTrade.Bid - PriceUnit * TPCoefRange);
         }
      } else if(isBetween(0.5 + CoreRange, perB, 1 - UntradeRange)) {
         PriceUnit = PriceUnit * TPCoefRange * TPCoefHalf;
         if(myPosition.isPositionInRange(POSITION_TYPE_SELL, PriceUnit)) return;
         myTrade.Sell(5, myTrade.Bid - PriceUnit * TPCoefHalf);
      } else if(isBetween(UntradeRange, perB, 0.5 - CoreRange)) {
         PriceUnit = PriceUnit * TPCoefRange * TPCoefHalf;
         if(myPosition.isPositionInRange(POSITION_TYPE_BUY, PriceUnit)) return;
         myTrade.Buy(0.01, myTrade.Ask + PriceUnit * TPCoefHalf);
      }
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
}
//+------------------------------------------------------------------+
