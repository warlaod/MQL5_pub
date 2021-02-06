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
input int PricePeriod,ATRPeriod;
input int MAPeriod,TrendPeriod;
input mis_MarcosTMP timeFrame, shortTimeframe,atrTimeframe;
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
MyPrice myPrice(PERIOD_MN1, 10);
CurrencyStrength CS(Timeframe, 1);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CiATR ATR;
CiMA MA;
int OnInit() {
   MyUtils myutils(60 * 1);
   myutils.Init();
   ATR.Create(_Symbol, ATRTimeframe, ATRPeriod);
   MA.Create(_Symbol,Timeframe,MAPeriod,0,MODE_EMA,PRICE_TYPICAL);

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
      MA.Refresh();

      double Highest = myPrice.Highest(0, PricePeriod);
      double Lowest = myPrice.Lowest(0, PricePeriod);
      double perB = (myPrice.At(0).close - Lowest) / (Highest - Lowest);

      if(perB > 0.5) {
            myTrade.setSignal(ORDER_TYPE_SELL);
      }

      if(perB < 0.5) {
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
