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
CiMA ciMALong, ciMAMiddle, ciMAShort;
CiBands ciLongBands, ciShortBands;
CiATR ciATR;

input ENUM_TIMEFRAMES MALongTimeframe, MAMiddleTimeframe, MAShortTimeframe,ATRTimeframe;
input ENUM_APPLIED_PRICE MAAppliedPrice;
input int MAPeriod;
input double LongMiddleCri, MiddleShortCri;
input int ATRCri;
input double TPCoef, SLCoef;
bool tradable = false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyTrade myTrade(0.1, false);

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   MyUtils myutils(14100, 60 * 27);
   myutils.Init();

   ciATR.Create(_Symbol, ATRTimeframe, MAPeriod);

   ciMALong.Create(_Symbol, MALongTimeframe, MAPeriod, 0, MODE_EMA, MAAppliedPrice);
   ciMAMiddle.Create(_Symbol, MAMiddleTimeframe, MAPeriod, 0, MODE_EMA, MAAppliedPrice);
   ciMAShort.Create(_Symbol, MAShortTimeframe, MAPeriod, 0, MODE_EMA, MAAppliedPrice);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   myPosition.Refresh();
   ciMALong.Refresh();
   ciMAMiddle.Refresh();
   ciMAShort.Refresh();
   ciATR.Refresh();
   myTrade.Refresh();


   if(!isBetween(MALongTimeframe, MAMiddleTimeframe, MAShortTimeframe)) return;

   if(!myTrade.istradable || !tradable) return;
   
   if(ciATR.Main(0) < ATRCri*_Point) return;

   if(MathAbs(ciMALong.Main(0) - ciMAMiddle.Main(0)) < ciATR.Main(0)*LongMiddleCri) return;
   if(MathAbs(ciMAMiddle.Main(0) - ciMAShort.Main(0)) < ciATR.Main(0)*MiddleShortCri) return;

   if(isBetween(ciMAShort.Main(0), ciMAMiddle.Main(0), ciMALong.Main(0))) {
      myTrade.signal = "buy";
   }

   if(isBetween(ciMALong.Main(0), ciMAMiddle.Main(0), ciMAShort.Main(0))) {
      myTrade.signal = "sell";
   }



   double PriceUnit = ciATR.Main(0);
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
   double result =  myTest.min_dd_and_mathsqrt_profit_trades();
   return  result;
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
