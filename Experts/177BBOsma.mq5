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
#include <Arrays\ArrayDouble.mqh>
CTrade trade;
CiOsMA ciOsma;
CiBands ciBands;
input ENUM_TIMEFRAMES BandTimeframe;
input double OsmaCri, OsmaDiffCri, OsmaCloseCri;
input int TPCoef, SLCoef;
input ENUM_APPLIED_PRICE OsmaAppliedPrice, BandAppliedPrice;
bool tradable = false;

double lastMaxOsma;
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
   trade.SetExpertMagicNumber(MagicNumber);

   ciOsma.Create(_Symbol, BandTimeframe, 12, 26, 9, OsmaAppliedPrice);
   ciBands.Create(_Symbol, BandTimeframe, 20, 0, 2, BandAppliedPrice);
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   myPosition.Refresh();
   ciBands.Refresh();
   ciOsma.Refresh();
   myTrade.Refresh();
   myPrice.Refresh();

   myTrade.CheckSpread();
   if(!myTrade.istradable || !tradable) return;

   double Osma2 = ciOsma.Main(2);
   double Osma1 = ciOsma.Main(1);
   double Osma0 = ciOsma.Main(0);

   if(MathAbs(Osma1) < OsmaCri * _Point) return;
   if(MathAbs(Osma1 - Osma0) < OsmaDiffCri * _Point) return;



   if( MathAbs(Osma1) > MathAbs(Osma0) && MathAbs(Osma1) > MathAbs(Osma2)) {
      if(Osma0 > 0 && ciBands.Upper(1) < myPrice.getData(1).close) {
         myTrade.signal = "sell";
         myPosition.CloseAllPositions(POSITION_TYPE_SELL);
         myPosition.CloseAllPositions(POSITION_TYPE_BUY);
      }
      if(Osma0 < 0 && ciBands.Lower(1) > myPrice.getData(1).close) {
         myTrade.signal = "buy";
         myPosition.CloseAllPositions(POSITION_TYPE_SELL);
         myPosition.CloseAllPositions(POSITION_TYPE_BUY);
      }
   }

   double PriceUnit = 10 * _Point;
   if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions / 2 && myTrade.signal == "buy") {
      if(myTrade.isInvalidTrade(myTrade.Ask - PriceUnit * SLCoef, myTrade.Ask + PriceUnit  * TPCoef)) return;
      trade.Buy(myTrade.lot, NULL, myTrade.Ask, myTrade.Ask - PriceUnit * SLCoef, myTrade.Ask + PriceUnit  * TPCoef, NULL);
      lastMaxOsma = Osma1;
   }
   if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions / 2 && myTrade.signal == "sell") {
      if(myTrade.isInvalidTrade(myTrade.Bid + PriceUnit * SLCoef, myTrade.Bid - PriceUnit * TPCoef)) return;
      trade.Sell(myTrade.lot, NULL, myTrade.Bid, myTrade.Bid + PriceUnit * SLCoef, myTrade.Bid - PriceUnit * TPCoef, NULL);
      lastMaxOsma = Osma1;
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

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
