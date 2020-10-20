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
CiMA ciMAShort, ciMALong;
CiStochastic ciStochastic;



input ENUM_TIMEFRAMES PriceTimeframe, MAShortTimeframe, MALongTimeframe;
input int TPCoef, SLCoef;
input int TrendPeriod, TrendCri;
bool tradable = false;
double lastopen;
string LTrend;
datetime LastTradeTime;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyTrade myTrade();
MyPrice myPrice(MAShortTimeframe, 2);

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   MyUtils myutils(60 * 27);
   myutils.Init();

   ciMAShort.Create(_Symbol, MAShortTimeframe, 10, 0, MODE_SMA, PRICE_CLOSE);
   ciMALong.Create(_Symbol, MALongTimeframe, 120, 0, MODE_SMA, PRICE_CLOSE);
   ciStochastic.Create(_Symbol, MAShortTimeframe, 5, 3, 3, MODE_SMA, STO_LOWHIGH);

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   myPosition.Refresh();
   myTrade.Refresh();
   myPrice.Refresh();
   ciMAShort.Refresh();
   ciMALong.Refresh();
   ciStochastic.Refresh();

   myTrade.CheckSpread();


   myTrade.CheckTradableTime("08:30", "14:00");

   MyOrder myOrder;




   if(ciStochastic.Main(2) > ciStochastic.Signal(2) && ciStochastic.Main(1) < ciStochastic.Signal(1))
      if(ciStochastic.Main(2) > 50)
         myPosition.CloseAllPositions(POSITION_TYPE_BUY);

   if(ciStochastic.Main(2) < ciStochastic.Signal(2) && ciStochastic.Main(1) > ciStochastic.Signal(1))
      if(ciStochastic.Main(2) < 50)
         myPosition.CloseAllPositions(POSITION_TYPE_SELL);

   if(myOrder.isOrderInTheSameBar(MAShortTimeframe)) myTrade.istradable = false;
   if(!myTrade.istradable || !tradable) return;

   double LongTrend = ciMALong.Main(1) - ciMALong.Main(TrendPeriod);
   double ShortTrend = ciMAShort.Main(1) - ciMAShort.Main(TrendPeriod);

   double ShortLongDistance2 = MathAbs(ciMALong.Main(2) - ciMAShort.Main(2));
   double ShortLongDistance1 = MathAbs(ciMALong.Main(1) - ciMAShort.Main(1));
   if(ShortLongDistance1 >= ShortLongDistance2) return;

   if(LongTrend > TrendCri * _Point && ciMALong.Main(1) < ciMAShort.Main(1)) {
      if(ciStochastic.Main(2) > ciStochastic.Signal(2) && ciStochastic.Main(1) < ciStochastic.Signal(1))
         if(ciStochastic.Main(2) > 50)
            myTrade.signal = "sell";
   }
   if(LongTrend < - TrendCri * _Point && ciMALong.Main(1) > ciMAShort.Main(1)) {
      if(ciStochastic.Main(2) < ciStochastic.Signal(2) && ciStochastic.Main(1) > ciStochastic.Signal(1))
         if(ciStochastic.Main(2) < 50)
            myTrade.signal = "buy";
   }

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
