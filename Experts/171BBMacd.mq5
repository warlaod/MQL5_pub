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
CiOsMA ciOsma;
CiBands ciLongBands, ciBands;
CiATR ciATR;

input ENUM_TIMEFRAMES BandTimeframe;
input int BandPeriod;
input ENUM_APPLIED_PRICE BandAppliedPrice, OsmaAppliedPrice;
input double TPCoef, SLCoef;
input double OsmaCri;

bool tradable = false;
string LastTrend, NewTrend;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyTrade myTrade();
MyPrice myPrice(BandTimeframe, 3);

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   MyUtils myutils(60 * 27);
   myutils.Init();
   ciOsma.Create(_Symbol, BandTimeframe, 12, 26, 9, OsmaAppliedPrice);
   ciBands.Create(_Symbol, BandTimeframe, BandPeriod, 0, 2, BandAppliedPrice);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   myPosition.Refresh();
   ciBands.Refresh();
   ciOsma.Refresh();
   myPrice.Refresh();
   myTrade.Refresh();

   if(MathAbs(ciOsma.Main(1)) < OsmaCri*_Point) return;
   if(!isBetween(MathAbs(ciOsma.Main(1)), MathAbs(ciOsma.Main(2)), MathAbs(ciOsma.Main(0)))) return;



   if(ciOsma.Main(0) < 0) NewTrend = "short";
   else NewTrend = "long";

   if(NewTrend == LastTrend) return;


   if(NewTrend == "short") {
      if(myPrice.getData(1).close < ciBands.Lower(1) && myPrice.getData(0).close > ciBands.Lower(0)) {
         myTrade.signal = "buy";
      }
   }

   if(NewTrend == "long") {
      if(myPrice.getData(1).close > ciBands.Upper(1) && myPrice.getData(0).close < ciBands.Upper(0)) {
         myTrade.signal = "sell";
      }
   }

   LastTrend = NewTrend;

   myTrade.CheckSpread();
   if(!myTrade.istradable || !tradable) return;

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
