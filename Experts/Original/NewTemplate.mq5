//+------------------------------------------------------------------+
//|                                                  NewTemplate.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
#include <MyPkg\OptimizedParameter.mqh>
#include <MyPkg\Trade\Trade.mqh>
#include <MyPkg\Trade\Volume.mqh>
#include <MyPkg\Price.mqh>
#include <MyPkg\Position\PositionStore.mqh>
#include <Indicators\TimeSeries.mqh>
#include <Indicators\Oscilators.mqh>
#include <Indicators\Trend.mqh>
#include <Indicators\BillWilliams.mqh>
#include <Indicators\Volumes.mqh>

int eventTimer = 60; // The frequency of OnTimer
input ulong magicNumber = 21984;
input int equityThereShold = 1500;
input int riskPercent = 5;
input optimizedTimeframes timeFrame;
ENUM_TIMEFRAMES tf = convertENUM_TIMEFRAMES(timeFrame);

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Trade trade(magicNumber);
Price price(tf);
Volume tVol(riskPercent);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CiAlligator Allig;
int OnInit() {
   EventSetTimer(eventTimer);

   Allig.Create(_Symbol, PERIOD_H1, 13, 8, 8, 5, 5, 3, MODE_LWMA, PRICE_CLOSE);
   Allig.BufferResize(8); // How many data should be referenced and updated

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   if(!CheckMarketOpen() || !CheckEquityThereShold(equityThereShold) || !CheckNewBarOpen(tf)) {
      return;
   }

   Allig.Refresh();
   double jaw = Allig.Jaw(-3);
   double teeth = Allig.Teeth(-3);
   double lips = Allig.Lips(-3);

   bool buyCondition = lips > teeth && teeth > jaw;
   bool sellCondition = lips < teeth && teeth < jaw;

   tradeRequest tR;
   if(buyCondition) {
      double ask = Ask();
      tradeRequest tR = {magicNumber, PERIOD_M5, ORDER_TYPE_BUY, ask, ask - 100 * _Point, ask + 100 * _Point};

      if(tVol.CalcurateVolume(tR)) {
         trade.PositionOpen(tR);
      }
   } else if(sellCondition) {
      double bid = Bid();
      tradeRequest tR = {magicNumber, PERIOD_M5, ORDER_TYPE_SELL, bid, bid + 100 * _Point, bid - 100 * _Point};

      if(tVol.CalcurateVolume(tR)) {
         trade.PositionOpen(tR);
      }
   }
}
//+------------------------------------------------------------------+
