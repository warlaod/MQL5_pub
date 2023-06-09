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
CiBands ciLongBand, ciShortBand;
CiFractals ciFractal;

double fractal_up[], fractal_down[];
int n;
double FractalDown[], FractalUp[];
double LowFractal_0, LowFractal_1, LowFractal_2, UpFractal_0, UpFractal_1, UpFractal_2 = 0;
int Indicator;

input ENUM_TIMEFRAMES FractalTimeframe;
input double TPCoef, SLCoef;
bool tradable = false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPrice myPrice(FractalTimeframe, 1);
MyPosition myPosition;
MyTrade myTrade(0.1, false);

// ATR, bottom,top個別
int OnInit() {
   MyUtils myutils(14100, 60 * 27);
   myutils.Init();

   Indicator = iFractals(_Symbol, FractalTimeframe);
   ArraySetAsSeries(FractalUp, true);
   ArraySetAsSeries(FractalDown, true);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   myPrice.Refresh();
   myPosition.Refresh();
   myTrade.Refresh();
   myTrade.CheckSpread();

   CopyBuffer(Indicator, 0, 0, 50, FractalUp);
   CopyBuffer(Indicator, 1, 0, 50, FractalDown);

   for(n = 0; n < 50; n++) {
      if(FractalUp[n] != EMPTY_VALUE) {
         if(FractalUp[n] != UpFractal_0) {
            UpFractal_2 = UpFractal_1;
            UpFractal_1 = UpFractal_0;
            UpFractal_0 = FractalUp[n];
         }
         break;
      }
   }



   for(n = 0; n < 50; n++) {
      if(FractalDown[n] != EMPTY_VALUE) {
         if(FractalDown[n] != LowFractal_0) {
            LowFractal_2 = LowFractal_1;
            LowFractal_1 = LowFractal_0;
            LowFractal_0 = FractalDown[n];
         }
         break;
      }

   }


   if(!myTrade.istradable || !tradable) return;

   if(UpFractal_1 > UpFractal_2 && UpFractal_1 > UpFractal_0) {
         myTrade.signal = "sell";
   }

   if(LowFractal_1 < LowFractal_2 && LowFractal_1 < LowFractal_0) {
         myTrade.signal = "buy";
   }

   double PriceUnit = UpFractal_0 - LowFractal_0;
   if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions / 2 && myTrade.signal == "buy") {
      if(myTrade.isInvalidTrade(myTrade.Ask - PriceUnit * SLCoef, myTrade.Ask + PriceUnit * TPCoef)) return;
      trade.Buy(myTrade.lot, NULL, myTrade.Ask, myTrade.Ask - PriceUnit * SLCoef, myTrade.Ask + PriceUnit * TPCoef, NULL);
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
   double result =  myTest.min_dd_and_mathsqrt_profit_trades();
   return  result;
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
