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
#include <Original\MyOrder.mqh>
#include <Indicators\TimeSeries.mqh>
#include <Indicators\Oscilators.mqh>
#include <Indicators\Trend.mqh>
#include <Trade\OrderInfo.mqh>
#include <Arrays\ArrayDouble.mqh>
#include <Indicators\BillWilliams.mqh>
CTrade trade;
CiMA ciMALong, ciMAShort;
CiBands ciBands;
CiMACD ciMacdLong, ciMacdShort;
CiStochastic ciStochastic;
#include <Generic\Interfaces\IComparable.mqh>

input int TPCoef, SLCoef;
input int TrendPeriod, MAPeriod;
input ENUM_TIMEFRAMES MAShortTimeframe, MACDLongTimeframe, MACDShortTimeframe;
input int positionCloseMin;
bool tradable = false;
input int TrendCri;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyTrade myTrade();
MyPrice myPrice(MAShortTimeframe, 10);
MyOrder myOrder;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   MyUtils myutils(60 * 27);
   myutils.Init();

   ciMacdLong.Create(_Symbol, MACDLongTimeframe, 12, 26, 9, PRICE_CLOSE);
   ciMacdShort.Create(_Symbol, MACDShortTimeframe, 12, 26, 9, PRICE_CLOSE);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   if(MACDLongTimeframe <= MACDShortTimeframe) return;
   Refresh();
   ciMacdLong.Refresh();
   ciMacdShort.Refresh();
   Check();
   

   
   

   double ShortOsma_new = ciMacdShort.Main(1) - ciMacdShort.Signal(1);
   double ShortOsma_old = ciMacdShort.Main(2) - ciMacdShort.Signal(2);
   double ShortOsma_older = ciMacdShort.Main(3) - ciMacdShort.Signal(3);
   double LongOsma = ciMacdLong.Main(0) - ciMacdLong.Signal(0);

   if(ShortOsma_old < 0 && ShortOsma_new > 0) myPosition.CloseAllPositions(POSITION_TYPE_SELL);
   if(ShortOsma_old > 0 && ShortOsma_new < 0) myPosition.CloseAllPositions(POSITION_TYPE_BUY);


   //myPosition.CloseAllPositionsInMinute(positionCloseMin);
   
   if(!myTrade.istradable || !tradable) return;





   if(LongOsma > 0 && ciMacdLong.Main(0) > 0) {
      if(ciMacdShort.Main(0) < 0 && ShortOsma_old < 0 && ShortOsma_new > 0)
         myTrade.signal = "buy";
   }

   if(LongOsma < 0 && ciMacdLong.Main(0) < 0) {
      if(ciMacdShort.Main(0) > 0 && ShortOsma_old > 0 && ShortOsma_new < 0)
         myTrade.signal = "sell";
   }

   double PriceUnit = 10 * _Point;
   if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions / 2 && myTrade.signal == "buy") {
      double SL = myPrice.Lowest(0, 7);
      if(myTrade.isInvalidTrade(SL, myTrade.Ask + 500 * _Point)) return;
      trade.Buy(myTrade.lot, NULL, myTrade.Ask, SL, myTrade.Ask + 500 * _Point, NULL);
   }

   if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions / 2 && myTrade.signal == "sell") {
      double SL = myPrice.Higest(0, 7);
      if(myTrade.isInvalidTrade(SL, myTrade.Bid -  500 * _Point)) return;
      trade.Sell(myTrade.lot, NULL, myTrade.Bid, SL, myTrade.Bid -  500 * _Point, NULL);
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

void Refresh(){
   myPosition.Refresh();
   myTrade.Refresh();
   myPrice.Refresh();
   myOrder.Refresh();
}

void Check(){
   myTrade.CheckSpread();
   //myTrade.CheckTradableTime("00:00","07:00");
   myTrade.CheckTradableTime("08:00","12:00");
   //myTrade.CheckTradableTime("14:00","24:00");
   if(myOrder.wasOrderedInTheSameBar(MACDShortTimeframe)) myTrade.istradable = false;
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
