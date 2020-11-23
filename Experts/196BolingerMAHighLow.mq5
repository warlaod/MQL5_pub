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

input double SLCoef, TPCoef;
input ENUM_TIMEFRAMES Timeframe, MAPeriod,TrendPeriod;
input int StopLossPeriod;
input double perBCri;
input int TrendCri;
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
CiBands Bands;
CiMA MA;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   MyUtils myutils(60 * 27);
   myutils.Init();
   MA.Create(_Symbol, Timeframe, 0, MAPeriod, MODE_SMA, PRICE_CLOSE);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   Refresh();
   Check();
   Bands.Refresh();
   MA.Refresh();
   myPrice.Refresh();

//myPosition.CloseAllPositionsInMinute(positionCloseMin);

   if(!myTrade.istradable || !tradable)
      return;

   double Highest = myPrice.Highest(0, StopLossPeriod);
   double Lowest = myPrice.Lowest(0, StopLossPeriod);

   double perB = (myPrice.At(0).close - Lowest) / (Highest - Lowest);
   if(perB  > 1 - perBCri || perB < perBCri)
      return;

   if(!isBetween(Highest, MA.Main(0), Lowest))
      return;

   double Trend = Bands.Base(0) - Bands.Base(TrendPeriod);
   
   if(isBetween(Highest, myPrice.At(0).close, MA.Main(0))) {
      if(Trend > - TrendCri*_Point) return;
      if(Bands.Upper(1) < myPrice.At(0).high) myTrade.setSignal(ORDER_TYPE_BUY);
   }

   if(isBetween(MA.Main(0), myPrice.At(0).close, Lowest)) {
      if(Trend < TrendCri*_Point) return;
      if(Bands.Lower(1) > myPrice.At(0).low) myTrade.setSignal(ORDER_TYPE_SELL);
   }



   double PriceUnit = 10 * _Point;
   if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions / 2)
      myTrade.Buy(Lowest, Bands.Upper(1));
   if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions / 2)
      myTrade.Sell(Highest, Bands.Lower(1));


}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer() {
   myPosition.Refresh();
   myTrade.Refresh();

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
   double result =  myTest.min_dd_and_mathsqrt_profit_trades();
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
//myDate.isInTime("01:00", "07:00");
   if(myOrder.wasOrderedInTheSameBar())
      myTrade.istradable = false;
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
