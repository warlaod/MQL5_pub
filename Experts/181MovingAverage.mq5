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
CiMA ciMALong, ciMAShort;
CiBands ciBands;
CiMACD ciMacdLong, ciMacdShort;
CiStochastic ciStochastic;
#include <Generic\Interfaces\IComparable.mqh>

input int TPCoef, SLCoef;
input ENUM_TIMEFRAMES MAShortTimeframe, MALongTimeframe, CSTimeframe;
input int TrendPeriod;
input int positionCloseMin;
bool tradable = false;
input int RangeTrendCri, LongTrendCri;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyTrade myTrade();
MyPrice myPrice(MAShortTimeframe, 10);
MyOrder myOrder;
CurrencyStrength CS(CSTimeframe, 1);;
int strong = 0;
int weak = 0;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   MyUtils myutils(60 * 27);
   myutils.Init();

   ciMAShort.Create(_Symbol, MAShortTimeframe, 10, 0, MODE_SMA, PRICE_CLOSE);
   ciMALong.Create(_Symbol, MALongTimeframe, 10, 0, MODE_SMA, PRICE_CLOSE);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   if(MALongTimeframe <= MAShortTimeframe) return;
   Refresh();
   ciMAShort.Refresh();
   ciMALong.Refresh();
   Check();

   string dwadwa = CS.StrongestCurrency();
   string dwadaw = CS.WeakestCurrency();
   
   if(CS.StrongestCurrency() == "AUD" && CS.WeakestCurrency() == "GBP" )
     {
      strong++;
     }


   double ShortTrend = ciMAShort.Main(0) - ciMAShort.Main(TrendPeriod);
   double LongTrend = ciMALong.Main(0) - ciMALong.Main(TrendPeriod);

   if(ShortTrend > 0) myPosition.CloseAllPositions(POSITION_TYPE_SELL);
   if(ShortTrend < 0) myPosition.CloseAllPositions(POSITION_TYPE_BUY);


   if(ciMAShort.Main(0) > ciMALong.Main(0) ) {
      if(ShortTrend > RangeTrendCri * _Point && LongTrend > LongTrendCri * _Point)
         if( myTrade.signal == "buybuy")
            myTrade.signal = "buy";
   }

   if(ciMAShort.Main(0) < ciMALong.Main(0) ) {
      if(ShortTrend < -RangeTrendCri * _Point && LongTrend < -LongTrendCri * _Point)
         if( myTrade.signal == "sellsell")
            myTrade.signal = "sell";
   }
   //myPosition.CloseAllPositionsInMinute(positionCloseMin);

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
   myPrice.Refresh();
   myOrder.Refresh();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Check() {
   myTrade.CheckSpread();
   //myTrade.CheckTradableTime("00:00","07:00");
   //myTrade.CheckTradableTime("08:00", "14:00");
   //myTrade.CheckTradableTime("14:00","24:00");
   if(myOrder.wasOrderedInTheSameBar(MAShortTimeframe)) myTrade.istradable = false;
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
