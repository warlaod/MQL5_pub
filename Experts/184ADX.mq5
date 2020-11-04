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
CiADX ciADX;
CiRSI ciRSIShort, ciRSIMiddle, ciRSILong;
#include <Generic\Interfaces\IComparable.mqh>

input int PricePeriod;
input int SLCoef, TPCoef;
input ENUM_TIMEFRAMES ADXTimeframe;
input int positionCloseMin;
bool tradable = false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyTrade myTrade();
MyPrice myPrice(ADXTimeframe, 1);
MyOrder myOrder(ADXTimeframe);
CurrencyStrength CS(ADXTimeframe, 1);;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   MyUtils myutils(60 * 27);
   myutils.Init();
   ciADX.Create(_Symbol,ADXTimeframe,14);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   Refresh();
   Check();

   ciRSILong.Refresh();
   ciRSIMiddle.Refresh();
   ciRSIShort.Refresh();
   ciADX.Refresh();
   myPrice.Refresh();
   
   if(ciADX.Plus(1) < ciADX.Main(1)) myPosition.CloseAllPositions(POSITION_TYPE_BUY);
   if(ciADX.Minus(1) < ciADX.Main(1)) myPosition.CloseAllPositions(POSITION_TYPE_SELL);
   
   //myPosition.CloseAllPositionsInMinute(positionCloseMin);

   myTrade.CheckSpread();

   if(!myTrade.istradable || !tradable) return;
   
   string STR = CS.StrongestCurrency();
   string WEK = CS.WeakestCurrency();

   if(ciADX.Plus(2) < ciADX.Main(2) && ciADX.Plus(1) > ciADX.Main(1)){
   
   myTrade.signal = "buy";
   }
   if(ciADX.Minus(2) < ciADX.Main(2) && ciADX.Minus(1) > ciADX.Main(1)) myTrade.signal = "sell";



   double Highest = myPrice.Higest(0, PricePeriod);
   double Lowest = myPrice.Lowest(0, PricePeriod);
   double PriceUnit = 10 * _Point;
   if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions / 2 && myTrade.signal == "buy") {
      if(myTrade.isInvalidTrade(Lowest, Highest + PriceUnit*TPCoef)) return;
      trade.Buy(myTrade.lot, NULL, myTrade.Ask, Lowest, Highest + PriceUnit*TPCoef, NULL);
   }

   if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions / 2 && myTrade.signal == "sell") {
      if(myTrade.isInvalidTrade(Highest, Lowest -  PriceUnit*TPCoef)) return;
      trade.Sell(myTrade.lot, NULL, myTrade.Bid, Highest, Lowest -  PriceUnit*TPCoef, NULL);
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
   //myTrade.CheckUntradableTime("01:00", "07:00");
   //myTrade.CheckTradableTime("00:00","07:00");
   //myTrade.CheckTradableTime("08:00", "14:00");
   //myTrade.CheckTradableTime("14:00","24:00");
   if(myOrder.wasOrderedInTheSameBar()) myTrade.istradable = false;
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
