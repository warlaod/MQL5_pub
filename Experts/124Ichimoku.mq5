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
#include <Original\MyUtils.mqh>
#include <Original\MyTrade.mqh>
#include <Original\MyCalculate.mqh>
#include <Original\MyTest.mqh>
#include <Original\MyPrice.mqh>
#include <Original\MyPosition.mqh>
#include <Indicators\TimeSeries.mqh>
#include <Indicators\Oscilators.mqh>
#include <Trade\OrderInfo.mqh>
#include <Indicators\Trend.mqh>
CTrade trade;
MyPosition myPosition;
CiIchimoku ciIchimoku;

input int IchimokuPeriod, SenkouCri, KijunCri;
input double TPCoef;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   MyUtils myutils();
   myutils.Init();
   ciIchimoku.Create(_Symbol,IchimokuTimeframe,9,26,52);
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   MyTrade myTrade(0.1, false);
   MyPosition myPosition;
   myTrade.CheckFridayEnd();
   myTrade.CheckYearsEnd();
   if(!myTrade.istradable){
      myPosition.CloseAllPositions(POSITION_TYPE_BUY);
      myPosition.CloseAllPositions(POSITION_TYPE_SELL);
   }


   myTrade.CheckSpread();
   if(!myTrade.istradable){
      return;
   }

   

   if( MathAbs(Senkou1[1] - Senkou2[1]) < SenkouCri * _Point || MathAbs(Senkou1[1] - Kijun[1]) < KijunCri * _Point) {
      return;
   }

   if(Tenkan[1] > Kijun[1] && Kijun[1] > Senkou1[1] && Senkou1[1] > Senkou2[1]) {
      signal = "buy";
   } else if(Tenkan[1] < Kijun[1] && Kijun[1] < Senkou1[1] && Senkou1[1] < Senkou2[1]) {
      signal = "sell";
   }


   double TPSLline = MathAbs(Tenkan[0] - Kijun[0]);

   if(EachPositionsTotal("buy") < positions / 2 && signal == "buy") {
      if(isNotInvalidTrade(Senkou1[1], Ask + TPSLline * TPCoef, Ask, true)) {
         trade.Buy(lot, NULL, Ask, Senkou1[1], Ask + TPSLline * TPCoef, NULL);
      }
   }

   if(EachPositionsTotal("sell") < positions / 2 && signal == "sell") {
      if(isNotInvalidTrade(Senkou1[1], Bid - TPSLline * TPCoef, Bid, false)) {
         trade.Sell(lot, NULL, Bid, Senkou1[1], Bid - TPSLline * TPCoef, NULL);
      }
   }
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
void OnTimer() {
   MyPosition myPosition;
   MyTrade myTrade(0.1, false);
   tradable  = true;

   myTrade.CheckFridayEnd();
   myTrade.CheckYearsEnd();

   if(!myTrade.istradable) {
      myPosition.CloseAllPositions(POSITION_TYPE_BUY);
      myPosition.CloseAllPositions(POSITION_TYPE_SELL);
      tradable = false;
   }

   myTrade.CheckBalance();
   if(!myTrade.istradable) {
      tradable = false;
   }

}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
