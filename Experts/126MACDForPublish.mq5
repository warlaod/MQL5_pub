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
CiMACD ciLongMACD, ciShortMACD;
CiATR ciATR;
input ENUM_TIMEFRAMES MacdShortTimeframe,MacdLongTimeframe;
input ENUM_APPLIED_PRICE MacdPriceType;
input int ATRPeriod, FastMacdPeriod, SlowMacdPeriod,SignalPeriod;
bool tradable = false;

input double TPCoef,SLCoef;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyTrade myTrade;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   MyUtils myutils(60 * 27);
   myutils.Init();
   trade.SetExpertMagicNumber(MagicNumber);
   
   ciLongMACD.Create(_Symbol,MacdLongTimeframe,FastMacdPeriod,SlowMacdPeriod,SignalPeriod,MacdPriceType);
   ciShortMACD.Create(_Symbol,MacdShortTimeframe,FastMacdPeriod,SlowMacdPeriod,SignalPeriod,MacdPriceType);
   ciATR.Create(_Symbol, MacdLongTimeframe, ATRPeriod);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   myPosition.Refresh();
   ciLongMACD.Refresh();
   ciShortMACD.Refresh();
   ciATR.Refresh();
   myTrade.Refresh();
   
   if(FastMacdPeriod >= SlowMacdPeriod) return;
   if(MacdShortTimeframe >= MacdLongTimeframe) return;
   
   myTrade.CheckSpread();
   if(!myTrade.istradable || !tradable) return;


   double LongHistogram[2];
   double ShortHistogram[2];
   for(int i=0; i<2; i++)
     {
      LongHistogram[i] = ciLongMACD.Main(i) - ciLongMACD.Signal(i);
      ShortHistogram[i] = ciShortMACD.Main(i) - ciShortMACD.Signal(i);
     }

   if(LongHistogram[0] > 0 && ciLongMACD.Main(0) > 0)
     {
      myTrade.signal ="buybuy";
     }
   else
      if(LongHistogram[0] < 0 && ciLongMACD.Main(0) < 0)
        {
         myTrade.signal ="sellsell";
        }

   if(ShortHistogram[1] < 0 && ShortHistogram[0] > 0 && ciShortMACD.Main(0) < 0 && myTrade.signal == "buybuy")
     {
      myTrade.signal = "buy";
     }
   else
      if(ShortHistogram[1] > 0 && ShortHistogram[0] < 0 && ciShortMACD.Main(0) > 0 && myTrade.signal == "sellsell")
        {
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
