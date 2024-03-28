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
#include <Trade\Trade.mqh>
#include <Original\MyUtils.mqh>
#include <Original\MyTrade.mqh>
#include <Original\Oyokawa.mqh>
#include <Original\MyCalculate.mqh>
#include <Original\MyTest.mqh>
#include <Original\MyPrice.mqh>
#include <Original\MyPosition.mqh>
#include <Original\MyOrder.mqh>
#include <Indicators\TimeSeries.mqh>
#include <Indicators\Oscilators.mqh>
#include <Indicators\Trend.mqh>
#include <Trade\OrderInfo.mqh>
#include <Arrays\ArrayDouble.mqh>
#include <Indicators\BillWilliams.mqh>
CTrade trade;
CiMA ciMALong, ciMAMiddle, ciMAShort;
CiBands ciBands;
CiATR ciATR;
CiOsMA ciOsma;
CiRSI ciRSI;
CiMACD ciMacdLong, ciMacdShort;
CiStochastic ciStochastic;
#include <Generic\Interfaces\IComparable.mqh>

input double TPCoef;
input int SLCoef;
input double Edge;
input ENUM_TIMEFRAMES LongTimeframe, ShortTimeframe;
input int PricePeriod, RSIPeriod, RSIRange, RSICri;
input int positionCloseMin;
bool tradable = false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyTrade myTrade();
MyPrice myLongPrice(LongTimeframe, 3);
MyPrice myShortPrice(ShortTimeframe, 3);
MyOrder myOrder(ShortTimeframe);
CurrencyStrength CS(ShortTimeframe, 1);;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   MyUtils myutils(60 * 27);
   myutils.Init();
   ciRSI.Create(_Symbol, LongTimeframe, RSIPeriod, PRICE_CLOSE);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   if(ShortTimeframe >= LongTimeframe) {
      return;
   }
   Refresh();
   Check();

   // ciOsma.Refresh();
   ciRSI.Refresh();
   myShortPrice.Refresh();
   myLongPrice.Refresh();
   //myPosition.CloseAllPositionsInMinute(positionCloseMin);

   double LongHighest = myLongPrice.Higest(1, RSIRange);
   double LongLowest = myLongPrice.Lowest(1, RSIRange);
   double CenterLine = (LongHighest + LongLowest) / 2;
   double Diff = LongHighest - LongLowest;

   double ShortHighest = myShortPrice.Higest(2, PricePeriod);
   double ShortLowest = myShortPrice.Lowest(2, PricePeriod);

   if(MathAbs(ciRSI.Main(0) - ciRSI.Main(RSIRange)) > RSICri) return;

   if(isBetween(CenterLine + Diff * Edge, myShortPrice.At(0).close, CenterLine)) {
      if(isBetween(myShortPrice.At(2).close, ShortLowest, myShortPrice.At(1).close))
         myTrade.signal = "sell";
   }

   if(isBetween(CenterLine, myShortPrice.At(0).close, CenterLine - Diff * Edge)) {
      if(isBetween(myShortPrice.At(1).close, ShortHighest, myShortPrice.At(2).close))
         myTrade.signal = "buy";
   }

   if(!myTrade.istradable || !tradable) return;

   double PriceUnit = 10 * _Point;
   if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions / 2 ) myTrade.Buy(ShortLowest - PriceUnit * SLCoef, ShortHighest + PriceUnit * TPCoef);
   if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions / 2 ) myTrade.Sell(ShortHighest + PriceUnit * SLCoef, ShortLowest -  PriceUnit * TPCoef);

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer() {
   myPosition.Refresh();
   myTrade.Refresh();

   tradable = true;

   myTrade.CheckFridayEnd();
   myTrade.CheckYearsEnd();
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
   myLongPrice.Refresh();
   myShortPrice.Refresh();
   myOrder.Refresh();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Check() {
   myTrade.CheckSpread();
   //myTrade.CheckUntradableTime("01:00", "07:00");
   //myTrade.CheckTradableTime("00:00","07:00");
   //myTrade.CheckTradableTime("08:00", "14:00");
   //myTrade.CheckTradableTime("14:00","24:00");
   if(myOrder.wasOrderedInTheSameBar()) myTrade.istradable = false;
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
