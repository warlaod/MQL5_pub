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
#include <Original\MyDate.mqh>
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
input int TPCoef, SLCoef;
input ENUM_TIMEFRAMES LongPriceTimeframe, ShortPriceTimeframe;
bool tradable = false;

datetime lastStopLossTime;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyTrade myTrade();
MyPrice myLongPrice(LongPriceTimeframe, 3);
MyPrice myShortPrice(ShortPriceTimeframe, 3);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   MyUtils myutils(60 * 27);
   myutils.Init();
   trade.SetExpertMagicNumber(MagicNumber);
   ciBands.Create(_Symbol, ShortPriceTimeframe, 20, 0, 3, PRICE_CLOSE);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   myPosition.Refresh();
   myTrade.Refresh();
   myLongPrice.Refresh();
   myShortPrice.Refresh();
   myTrade.CheckSpread();
   ciBands.Refresh();
   
   if(LongPriceTimeframe <= ShortPriceTimeframe) return;


   if(myLongPrice.RosokuIsPlus(2) && myLongPrice.RosokuIsPlus(1)) {
      if(myLongPrice.getData(2).high < myLongPrice.getData(1).close)
         myTrade.signal = "buybuy";
   } else if(!myLongPrice.RosokuIsPlus(2) && !myLongPrice.RosokuIsPlus(1)) {
      if(myLongPrice.getData(2).low > myLongPrice.getData(1).close)
         myTrade.signal = "sellsell";
   }

   if(myTrade.signal == "buybuy" && myLongPrice.getData(2).high > myLongPrice.getData(0).close) {
      myPosition.CloseAllPositions(POSITION_TYPE_BUY);
      lastStopLossTime = TimeCurrent();
   }
   if(myTrade.signal == "sellsell" && myLongPrice.getData(2).low < myLongPrice.getData(0).close) {
      myPosition.CloseAllPositions(POSITION_TYPE_SELL);
      lastStopLossTime = TimeCurrent();
   }

   if(myTrade.signal == "buybuy") {
      if(ciBands.Lower(1) > myLongPrice.getData(1).close) myTrade.signal = "buy";
      myPosition.CloseAllPositions(POSITION_TYPE_SELL);
   }
   if(myTrade.signal == "sellsell") {
      if(ciBands.Upper(1) < myLongPrice.getData(1).close) myTrade.signal = "sell";
      myPosition.CloseAllPositions(POSITION_TYPE_BUY);
   }

   if(NewBarsCount(lastStopLossTime, LongPriceTimeframe) == 0) return;
   if(!myTrade.istradable || !tradable) return;



   double PriceUnit = 10 * _Point;
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
   MyDate myDate();
   myDate.Refresh();
   myTrade.CheckFridayEnd();
   myDate.CheckYearsEnd();
   myTrade.CheckBalance();
   myTrade.CheckMarginLevel();
   
   myDate.CheckDST_USA();
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
