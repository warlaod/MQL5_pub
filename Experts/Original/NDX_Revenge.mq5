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
#include <MyPkg\Optimization.mqh>
#include <MyPkg\Trade\Trade.mqh>
#include <MyPkg\Trade\Volume.mqh>
#include <MyPkg\Price.mqh>
#include <MyPkg\Position\PositionStore.mqh>
#include <MyPkg\Time.mqh>
#include <MyPkg\Trailing\Appointed.mqh>
#include <MyPkg\Trailing\Pips.mqh>
#include <Indicators\TimeSeries.mqh>
#include <Indicators\Oscilators.mqh>
#include <Indicators\Trend.mqh>
#include <Indicators\BillWilliams.mqh>
#include <Indicators\Volumes.mqh>

int eventTimer = 60; // The frequency of OnTimer
input ulong magicNumber = 21984;
input int equityThereShold = 1500;
input int riskPercent = 2;
input int positionTotal = 1;
input int whenToCloseOnFriday = 23;
input int spreadLimit = 999;
input optimizedTimeframes timeFrame;
ENUM_TIMEFRAMES tf = convertENUM_TIMEFRAMES(timeFrame);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int digitAdjust = DigitAdjust();
double pips = Pips();
Trade trade(magicNumber);
Price price(tf);
Volume tVol(riskPercent);
PositionStore positionStore(magicNumber);
Time time;

input int adxMinusMin, adxPlusMin;
input int atrPeriod, atrMinVal;
input double slPips;
input int adxPeriod;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CiATR ATR;
CiADX ADX;
Pips trailing;
int OnInit() {
   EventSetTimer(eventTimer);
   ATR.Create(_Symbol, tf, atrPeriod);
   ATR.BufferResize(1);

   ADX.Create(_Symbol, tf, adxPeriod);
   ADX.BufferResize(1);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   time.Refresh();
   positionStore.Refresh();

   trailing.TrailLong(positionStore.sellTickes, 50, slPips);
   trailing.TrailShort(positionStore.sellTickes, 50, slPips);

   // don't trade before 2 hours from market close
   if(time.CheckTimeOver(FRIDAY, whenToCloseOnFriday - 2)) {
      if(time.CheckTimeOver(FRIDAY, whenToCloseOnFriday - 1)) {
         trade.ClosePositions(positionStore.buyTickes);
         trade.ClosePositions(positionStore.sellTickes);
      }
      return;
   }

   if(!CheckMarketOpen() || !CheckEquityThereShold(equityThereShold) || !CheckNewBarOpen(tf)) {
      return;
   }

   if(SymbolInfoInteger(Symbol(), SYMBOL_SPREAD) > spreadLimit) {
      return;
   }

   ATR.Refresh();
   double atr = ATR.Main(0);
   if(ATR.Main(0) < atrMinVal * _Point * digitAdjust) return;

   bool buyCondition = (ADX.Minus(0) > 20 && ADX.Main(0) < adxMinusMin &&  ADX.Plus(1) > ADX.Plus(2));
   bool sellCondition = (ADX.Plus(0) > 20 && ADX.Main(0) > adxPlusMin && ADX.Minus(1) > ADX.Minus(2));

   tradeRequest tR;

   if(buyCondition) {
      double ask = Ask();
      double sl = 0;
      double tp = ask + 50 * pips;
      tradeRequest tR = {magicNumber, tf, ORDER_TYPE_BUY, ask, sl, tp};

      if(positionStore.buyTickes.Total() < positionTotal && tVol.CalcurateVolume(tR)) {
         trade.OpenPosition(tR);
      }
   } else if(sellCondition) {
      double bid = Bid();
      double sl = bid + slPips * pips;
      double tp = bid - 50 * pips;
      tradeRequest tR = {magicNumber, tf, ORDER_TYPE_SELL, bid, sl, tp};

      if(positionStore.sellTickes.Total() < positionTotal && tVol.CalcurateVolume(tR)) {
         trade.OpenPosition(tR);
      }
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double OnTester() {
   Optimization optimization;
   return optimization.Custom2();
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
