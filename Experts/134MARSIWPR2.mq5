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
CiMomentum ciMomentum;
CiRSI ciRSI;
CiATR ciATR;
CTrade trade;

input ENUM_TIMEFRAMES MomentumTimeframe, RSITimeframe;
input int RSIPeriod;
input ENUM_APPLIED_PRICE MomentumAppliedPrice, RSIAppliedPrice;
input double SLCoef, TPCoef;
input int RSICri;
input double CandleLowCloseCri, CandleHighCloseCri;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPrice myPrice(RSITimeframe, RSIPeriod);
MyPosition myPosition;
MyTrade myTrade(0.1, false);

bool tradable = true;
int OnInit() {
   MyUtils myutils(13400, 60 * 20);
   myutils.Init();

   ciATR.Create(_Symbol, RSITimeframe, RSIPeriod);
   ciRSI.Create(_Symbol, RSITimeframe, RSIPeriod, RSIAppliedPrice);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
// ATR, top.bottomはhighest-lowest
void OnTimer() {
   myPrice.Refresh();
   myPosition.Refresh();
   myTrade.Refresh();

   tradable = true;

   myTrade.CheckFridayEnd();
   myTrade.CheckYearsEnd();
   myTrade.CheckBalance();

   if(!myTrade.istradable) {
      myPosition.CloseAllPositions(POSITION_TYPE_BUY);
      tradable = false;
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   ciATR.Refresh();
   ciRSI.Refresh();
   myPrice.Refresh();
   myPosition.Refresh();

   double current_price = myPrice.getData(0).close;
   double candle_length = MathAbs(current_price - myPrice.getData(0).open);
   double candle_low_close = MathAbs(current_price - myPrice.getData(0).low);
   double candle_high_close = MathAbs(current_price - myPrice.getData(0).high);


   myTrade.CheckSpread();
   if(!myTrade.istradable || !tradable) return;
   if(myPosition.Total >= positions) return;

   if(candle_length < 10 * _Point) return;

   double ATR = ciATR.Main(0);
   if( MathAbs(ciRSI.Main(0) - 50) < RSICri) {
      if( candle_low_close / (candle_low_close + candle_length) > CandleLowCloseCri) {
         if( candle_high_close / (candle_high_close + candle_length) < CandleHighCloseCri) {
            if(isNotInvalidTrade(myTrade.Ask - ATR * SLCoef, myTrade.Ask + ATR * TPCoef, myTrade.Ask, true))
               trade.Buy(myTrade.lot, NULL, myTrade.Ask, myTrade.Ask - ATR * SLCoef, myTrade.Ask + ATR * TPCoef, NULL);
         }
      }
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
