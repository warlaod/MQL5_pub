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
#include <Indicators\BillWilliams.mqh>
CTrade trade;
CiStochastic ciStochastic;
CiSAR ciSAR;
CiBands ciLongBands, ciBands;
CiATR ciATR;

input ENUM_TIMEFRAMES BandTimeframe;
input int BandPeriod;
input double Deviation;
input ENUM_APPLIED_PRICE BandAppliedPrice;
input int BandWidthRange;
input double BoxCri, TrendCri, PriceCri;
input double TPCoef, SLCoef;
input int perBLowCri, perBHighCri;
bool tradable = false;
string Trend;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyTrade myTrade(0.1, false);
MyPrice myPrice(BandTimeframe, 3);

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   MyUtils myutils(14100, 60 * 27);
   myutils.Init();

   ciBands.Create(_Symbol, BandTimeframe, BandPeriod, 0, Deviation, BandAppliedPrice);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   myPosition.Refresh();
   ciBands.Refresh();
   myPrice.Refresh();
   myTrade.Refresh();


   if(!myTrade.istradable || !tradable) return;


   CArrayDouble BandWidth;
   for(int i = 0; i <= BandWidthRange; i++) {
      BandWidth.Add(ciBands.Upper(i) - ciBands.Lower(i));
      double dwa  = BandWidth.At(i);
      string aw = "fewa";
   }

   if( BandWidth.At(0) / BandWidth.At(BandWidth.Maximum(0, BandWidthRange)) <= BoxCri) {
      Trend = "Box";
   } else if( BandWidth.At(BandWidth.Minimum(0, BandWidthRange)) / BandWidth.At(0) >= TrendCri) {
      Trend = "Trend";
   }

   if(Trend == "Trend") {
      double perB = (myPrice.getData(0).close - ciBands.Lower(0)) / (ciBands.Upper(0) - ciBands.Lower(0)) * 100;
      if(perB > 50 + perBLowCri && perB < 100 - perBHighCri) myTrade.signal = "buy";
      if(perB <  50 - perBLowCri && perB > 0 + perBHighCri) myTrade.signal = "sell";
   } else if(Trend != "Box") {
      if(myPrice.getData(1).high > ciBands.Upper(1) && myPrice.getData(1).close - myPrice.getData(1).open > 0 && myPrice.getData(0).close > myPrice.getData(1).close) {
         if( myPrice.RosokuHigh(1) / myPrice.RosokuBody(1) > PriceCri) return;
         myTrade.signal = "buy";
         Trend = "";
      }

      if(myPrice.getData(1).low < ciBands.Lower(1) && myPrice.getData(1).close - myPrice.getData(1).open < 0 && myPrice.getData(0).close < myPrice.getData(1).close) {
         if( myPrice.RosokuLow(1) / myPrice.RosokuBody(1) > PriceCri) return;
         myTrade.signal = "sell";
         Trend = "";
      }
   }

   double PriceUnit = ciBands.Upper(0) - ciBands.Lower(0);
   if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions / 2 && myTrade.signal == "buy") {
      if(myTrade.isInvalidTrade(myTrade.Ask - PriceUnit * SLCoef, myTrade.Ask + PriceUnit  * TPCoef)) return;
      trade.Buy(myTrade.lot, NULL, myTrade.Ask, myTrade.Ask - PriceUnit * SLCoef, myTrade.Ask + PriceUnit  * TPCoef, NULL);
   }

   if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions / 2 && myTrade.signal == "sell") {
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
   double result =  myTest.min_dd_and_mathsqrt_profit_trades_only_longs();
   return  result;
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
