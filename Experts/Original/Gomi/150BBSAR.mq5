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
CiSAR ciSAR;
CiBands ciBands;
CiATR ciATR;

input ENUM_TIMEFRAMES BandsTimeframe, SARTimeframe;
input int BandPeriod, Deviation;
input ENUM_APPLIED_PRICE BandAppliedPrice;
input double TPBuyCoef, SLBuyCoef,TPSellCoef,SLSellCoef;
input int RosokuCri;
bool tradable = false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyTrade myTrade(0.1, false);
MyPrice myPrice(BandsTimeframe, 1);

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   MyUtils myutils(14100, 60 * 27);
   myutils.Init();

   ciBands.Create(_Symbol, BandsTimeframe, BandPeriod, 0, Deviation, BandAppliedPrice);
   ciSAR.Create(_Symbol, SARTimeframe, 0.02, 0.2);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   myPosition.Refresh();
   ciBands.Refresh();
   ciSAR.Refresh();
   myPrice.Refresh();
   myTrade.Refresh();
   
   if(!myTrade.istradable || !tradable) return;

   if(ciSAR.Main(0) < myPrice.getData(0).close) {
      if(ciBands.Lower(0) > myPrice.getData(0).low) {
         if(myPrice.RosokuLow(0) > RosokuCri * _Point) {
            myTrade.signal = "buy";
         }
      }
   }

   if(ciSAR.Main(0) > myPrice.getData(0).close) {
      if(ciBands.Upper(0) < myPrice.getData(0).high) {
         if(myPrice.RosokuHigh(0) > RosokuCri * _Point) {
            myTrade.signal = "sell";
         }
      }
   }

   if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions / 2 && myTrade.signal == "buy") {
      if(myTrade.isInvalidTrade(ciBands.Lower(0) * SLBuyCoef, ciBands.Upper(0)  * TPBuyCoef)) return;
      trade.Buy(myTrade.lot, NULL, myTrade.Ask, ciBands.Lower(0) * SLBuyCoef, ciBands.Upper(0)  * TPBuyCoef, NULL);
   }

   if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions / 2 && myTrade.signal == "sell") {
      if(myTrade.isInvalidTrade(ciBands.Upper(0) * SLSellCoef, ciBands.Lower(0) * TPBuyCoef)) return;
      trade.Sell(myTrade.lot, NULL, myTrade.Bid, ciBands.Upper(0) * SLSellCoef, ciBands.Lower(0) * TPBuyCoef, NULL);
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
