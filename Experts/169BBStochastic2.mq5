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
CiRSI ciRSI, ciRSIMiddle, ciRSILong;
CiStochastic ciStochastic;
CiATR ciATR;
CiMomentum ciMomentum;
CiBands ciBands;
input ENUM_TIMEFRAMES MomentumTimeframe;
input ENUM_APPLIED_PRICE MomentumAppliedPrice;
input double SLCoef, TPCoef;
input int k, s, d;
input int MomentumPeriod;
input int SellStochasticCri, BuyStochasticCri, CloseBuyStochasticCri, CloseSellStochasticCri;
bool tradable = false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyTrade myTrade();
MyPrice myPrice(MomentumTimeframe, 2);

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   MyUtils myutils(60 * 27);
   myutils.Init();
   trade.SetExpertMagicNumber(MagicNumber);

   ciMomentum.Create(_Symbol, MomentumTimeframe, MomentumPeriod, MomentumAppliedPrice);
   ciStochastic.Create(_Symbol, MomentumTimeframe, k, d, s, MODE_EMA, STO_LOWHIGH);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   myPosition.Refresh();
   ciStochastic.Refresh();
   ciMomentum.Refresh();
   myTrade.Refresh();
   myPrice.Refresh();


   myTrade.CheckSpread();
   //myPosition.Trailings(POSITION_TYPE_BUY,myTrade.Ask - (ciBands.Upper(0)-ciBands.Lower(0))*TrailingCoef);
   //myPosition.Trailings(POSITION_TYPE_SELL,myTrade.Bid + (ciBands.Upper(0)-ciBands.Lower(0))*TrailingCoef);
   if(!myTrade.istradable || !tradable) return;



   if(ciStochastic.Main(0) > CloseBuyStochasticCri || ciStochastic.Signal(0) > CloseBuyStochasticCri) {
      if(ciStochastic.Main(1) > ciStochastic.Signal(1) &&  ciStochastic.Main(0) < ciStochastic.Signal(0))
        myPosition.CloseAllPositions(POSITION_TYPE_BUY);
   }

   if(ciStochastic.Main(0) < CloseSellStochasticCri || ciStochastic.Signal(0) < CloseSellStochasticCri) {
      if(ciStochastic.Main(1) < ciStochastic.Signal(1) &&  ciStochastic.Main(0) > ciStochastic.Signal(0))
         myPosition.CloseAllPositions(POSITION_TYPE_SELL);
   }


   if(ciMomentum.Main(0) < 100 ) {
      if(ciStochastic.Main(0) > SellStochasticCri || ciStochastic.Signal(0) > SellStochasticCri) {
         if(ciStochastic.Main(1) > ciStochastic.Signal(1) &&  ciStochastic.Main(0) < ciStochastic.Signal(0))
            myTrade.signal = "sell";
      }
   }

   if(ciMomentum.Main(0) > 100) {
      if(ciStochastic.Main(0) < BuyStochasticCri || ciStochastic.Signal(0) < BuyStochasticCri) {
         if(ciStochastic.Main(1) < ciStochastic.Signal(1) &&  ciStochastic.Main(0) > ciStochastic.Signal(0))
            myTrade.signal = "buy";
      }
   }

   double PriceUnit =10*_Point;
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
