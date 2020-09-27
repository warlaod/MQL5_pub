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
CiADX ciADX;
CiOsMA ciOsma;
CiBands ciLongBands, ciBands;
CiATR ciATR;

input ENUM_TIMEFRAMES StochasticTimeframe, ADXTimeframe;
input int ADXPeriod, ATRPeriod;
input ENUM_STO_PRICE Sto_PRICE;
input int k, d, s;
input int StochasticHighCri, StochasticLowCri;
input double TPCoef, SLCoef;
input int ADXCri;
bool tradable = false;
string LTrend;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyTrade myTrade();
MyPrice myPrice(StochasticTimeframe, 3);

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   MyUtils myutils(60 * 27);
   myutils.Init();
   ciADX.Create(_Symbol, ADXTimeframe, ADXPeriod);
   ciStochastic.Create(_Symbol, StochasticTimeframe, k, d, s, MODE_EMA, Sto_PRICE);
   ciATR.Create(_Symbol, ADXTimeframe, ATRPeriod);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   myPosition.Refresh();
   ciATR.Refresh();
   ciStochastic.Refresh();
   ciADX.Refresh();
   myTrade.Refresh();


   if(ciADX.Main(0) > ADXCri) return;
   myTrade.CheckSpread();
   if(!myTrade.istradable || !tradable) return;

   if(ciStochastic.Main(1) > StochasticHighCri && ciStochastic.Signal(1) > StochasticHighCri) {
      if(ciStochastic.Main(1) > ciStochastic.Signal(1) && ciStochastic.Main(0) < ciStochastic.Signal(0))
         myTrade.signal = "sell";
   }

   else if(ciStochastic.Main(1) < StochasticLowCri && ciStochastic.Signal(1) < StochasticLowCri) {
      if(ciStochastic.Main(1) < ciStochastic.Signal(1) && ciStochastic.Main(0) > ciStochastic.Signal(0))
         myTrade.signal = "buy";
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
   double result =  myTest.min_dd_and_mathsqrt_profit_trades_only_longs();
   return  result;
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
