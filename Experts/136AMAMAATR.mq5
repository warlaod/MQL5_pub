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
CTrade trade;

CiATR ciATR;
CiMA ciMA;
CiAMA ciAMA;

input ENUM_TIMEFRAMES MATimeframe;
input int MAPeriod;
input ENUM_APPLIED_PRICE  MAAppliedPrice;
input int ATRCri,CandleLengthCri;
input double CandleHighCloseCri, SLCoef, TPCoef;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPrice myPrice(MATimeframe, 2);
MyPosition myPosition;
MyTrade myTrade(0.1, false);

bool tradable = true;
int OnInit() {
   MyUtils myutils(13400, 60 * 20);
   myutils.Init();

   ciMA.Create(_Symbol, MATimeframe, MAPeriod, 0, MODE_EMA, MAAppliedPrice);
   ciATR.Create(_Symbol, MATimeframe, MAPeriod);
   ciAMA.Create(_Symbol, MATimeframe, 9, 2, 30, 0, MAAppliedPrice);

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
   myTrade.Refresh();
   myTrade.CheckSpread();
   if(!myTrade.istradable || !tradable) return;

   myPosition.Refresh();
   if(myPosition.Total >= positions/2) return;

   ciATR.Refresh();
   ciMA.Refresh();
   ciAMA.Refresh();
   myPrice.Refresh();


   double current_price = myPrice.getData(1).close;
   double candle_length = MathAbs(current_price - myPrice.getData(1).open);
   double candle_high_close = MathAbs(current_price - myPrice.getData(1).high);
   double ATR = ciATR.Main(0);

   if(candle_length < CandleLengthCri * _Point) return;
   if(candle_high_close / (candle_high_close + candle_length) > CandleHighCloseCri) return;
   if(current_price - myPrice.getData(1).open < 0) return;
   if(ATR < ATRCri * _Point) return;
   

   if(ciMA.Main(1) - ciAMA.Main(1) > 0 && ciMA.Main(0) - ciAMA.Main(0) < 0) {
      if(isNotInvalidTrade(myTrade.Ask - ATR * SLCoef, myTrade.Ask + ATR * TPCoef, myTrade.Ask, true))
         trade.Buy(myTrade.lot, NULL, myTrade.Ask, myTrade.Ask - ATR * SLCoef, myTrade.Ask + ATR * TPCoef, NULL);
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
