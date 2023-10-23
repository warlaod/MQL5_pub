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
CiMA ciMA;


input ENUM_TIMEFRAMES PriceTimeframe;
input ENUM_MA_METHOD MA_Metogod;
input ENUM_APPLIED_PRICE AppliedPrice;
input int TPCoef, SLCoef;
input int BodyCri, MACri,EntryCri;
bool tradable = false;
double lastopen;
string LTrend;
datetime LastTradeTime;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyTrade myTrade();
MyPrice myPrice(PriceTimeframe, 2);

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   MyUtils myutils(60 * 27);
   myutils.Init();

   ciMA.Create(_Symbol, PriceTimeframe, 14, 0, MA_Metogod, AppliedPrice);

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   myPosition.Refresh();
   myTrade.Refresh();
   myPrice.Refresh();
   ciMA.Refresh();

   myTrade.CheckSpread();



   if(!myTrade.istradable || !tradable) return;

   if(myPrice.RosokuBody(1) > BodyCri * _Point) return;

   if(MathAbs(myPrice.getData(1).close - ciMA.Main(1)) < MACri * _Point) return;

   if(myPrice.RosokuIsPlus(1) && myPrice.getData(1).close < ciMA.Main(1)) {
      if(myPrice.getData(0).close - myPrice.getData(1).close > EntryCri*_Point)
      myTrade.signal = "buy";
   }

   if(!myPrice.RosokuIsPlus(1) && myPrice.getData(1).close > ciMA.Main(1)) {
       if(myPrice.getData(1).close - myPrice.getData(0).close > EntryCri*_Point)
      myTrade.signal = "sell";
   }
   
   int dwad = Bars(_Symbol, PriceTimeframe, LastTradeTime, TimeCurrent());
   
   if(Bars(_Symbol, PriceTimeframe, LastTradeTime, TimeCurrent()) == 0) return;
   double PriceUnit = 10 * _Point;
   if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions / 2 && myTrade.signal == "buy") {
      if(myTrade.isInvalidTrade(myTrade.Ask - PriceUnit * SLCoef, myTrade.Ask + PriceUnit  * TPCoef)) return;
      trade.Buy(myTrade.lot, NULL, myTrade.Ask, myTrade.Ask - PriceUnit * SLCoef, myTrade.Ask + PriceUnit  * TPCoef, NULL);
      LastTradeTime = TimeCurrent();
   }

   if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions / 2 && myTrade.signal == "sell") {
      if(myTrade.isInvalidTrade(myTrade.Bid + PriceUnit * SLCoef, myTrade.Bid - PriceUnit * TPCoef)) return;
      trade.Sell(myTrade.lot, NULL, myTrade.Bid, myTrade.Bid + PriceUnit * SLCoef, myTrade.Bid - PriceUnit * TPCoef, NULL);
      LastTradeTime = TimeCurrent();
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

   int hours[] = {8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23};


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
