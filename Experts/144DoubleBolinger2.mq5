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
#include <Original\prices.mqh>
#include <Original\positions.mqh>
#include <Original\period.mqh>
#include <Original\account.mqh>
#include <Original\caluculate.mqh>
#include <Original\MyUtils.mqh>
#include <Original\MyTrade.mqh>
#include <Original\MyCalculate.mqh>
#include <Original\MyTest.mqh>
#include <Original\MyPrice.mqh>
#include <Original\MyPosition.mqh>
#include <Indicators\TimeSeries.mqh>
#include <Indicators\Oscilators.mqh>
#include <Indicators\Trend.mqh>
#include <Trade\OrderInfo.mqh>
#include <Arrays\ArrayDouble.mqh>
CTrade trade;
CiBands ciLongBand, ciShortBand;

input ENUM_TIMEFRAMES ShortBandTimeframe, LongBandTimeframe;
input ENUM_APPLIED_PRICE BandAppliedPrice;

input double Deviation;

input int BandWidthRange;
input double LongBandWidthCri, ShortBandWidthCri;

input double TPCoef, SLCoef;
bool tradable = false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPrice myPrice(ShortBandTimeframe, 3);
MyPosition myPosition;
MyTrade myTrade(0.1, false);

// ATR, bottom,top個別
int OnInit() {
   MyUtils myutils(14100, 60 * 27);
   myutils.Init();
   ciLongBand.Create(_Symbol, LongBandTimeframe, 20, 0, Deviation, BandAppliedPrice);
   ciShortBand.Create(_Symbol, ShortBandTimeframe, 20, 0, Deviation, BandAppliedPrice);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   myPrice.Refresh();
   myPosition.Refresh();
   myTrade.Refresh();
   ciLongBand.Refresh();
   ciShortBand.Refresh();
   myTrade.CheckSpread();

   if(!myTrade.istradable || !tradable) return;

   CArrayDouble ShortBandWidth, LongBandWidth;
   for(int i = 0; i < BandWidthRange; i++) {
      double dwa  = ciShortBand.Upper(i);
      double fa = ciShortBand.Lower(i);
      double dawda = ciShortBand.Upper(i) - ciShortBand.Lower(i);
      ShortBandWidth.Add(ciShortBand.Upper(i) - ciShortBand.Lower(i));
      LongBandWidth.Add(ciLongBand.Upper(i) - ciLongBand.Lower(i));
   }

   double dawd = ShortBandWidth.At(0);
   double dwa =  ShortBandWidth[ShortBandWidth.Minimum(0, BandWidthRange - 1)];

   if(LongBandWidth.At(0) / LongBandWidth[LongBandWidth.Minimum(0, BandWidthRange - 1)] < LongBandWidthCri) return;
   if(ShortBandWidth.At(0) / ShortBandWidth[ShortBandWidth.Minimum(0, BandWidthRange - 1)] > ShortBandWidthCri) return;

   if(ciShortBand.Lower(2) > myPrice.getData(2).close && ciShortBand.Lower(1) > myPrice.getData(1).close) {
      myTrade.signal = "sell";
   } else if(ciShortBand.Upper(2) < myPrice.getData(2).close && ciShortBand.Upper(1) < myPrice.getData(1).close) {
      myTrade.signal = "buy";
   }

   if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions / 2 && myTrade.signal == "buy") {
      double PriceUnit = ciShortBand.Upper(0) - ciShortBand.Base(0);
      if(myTrade.isInvalidTrade(myTrade.Ask - PriceUnit * SLCoef, myTrade.Ask + PriceUnit * TPCoef)) return;
      trade.Buy(myTrade.lot, NULL, myTrade.Ask, myTrade.Ask - PriceUnit * SLCoef, myTrade.Ask + PriceUnit * TPCoef, NULL);
   }

   if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions / 2 && myTrade.signal == "sell") {
      double PriceUnit = ciShortBand.Lower(0) - ciShortBand.Base(0);
      if(myTrade.isInvalidTrade(myTrade.Bid + PriceUnit * SLCoef, myTrade.Bid - PriceUnit * TPCoef)) return;
      trade.Sell(myTrade.lot, NULL, myTrade.Bid, myTrade.Bid + PriceUnit * SLCoef, myTrade.Bid - PriceUnit * TPCoef, NULL);
   }
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

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
