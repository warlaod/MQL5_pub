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
#include <MyPkg\Trade\VolumeByMargin.mqh>
#include <MyPkg\Price.mqh>
#include <MyPkg\Position\PositionStore.mqh>
#include <MyPkg\Position\Position.mqh>
#include <MyPkg\Time.mqh>
#include <MyPkg\OrderHistory.mqh>
#include <Indicators\TimeSeries.mqh>
#include <Indicators\Oscilators.mqh>
#include <Indicators\Trend.mqh>
#include <Indicators\BillWilliams.mqh>
#include <Indicators\Volumes.mqh>

int eventTimer = 60; // The frequency of OnTimer
input ulong magicNumber = 21984;
input int equityThereShold = 1500;
input int riskPercent = 5;
input int positionTotal = 1;
input int whenToCloseOnFriday = 23;
input int spreadLimit = 999;
input optimizedTimeframes timeFrame;
ENUM_TIMEFRAMES tf = convertENUM_TIMEFRAMES(timeFrame);
input optimizedTimeframes adxTimeFrame;
ENUM_TIMEFRAMES adxTf = convertENUM_TIMEFRAMES(adxTimeFrame);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

string symbol = _Symbol;
double pips = Pips(symbol);
Trade trade(magicNumber);
Price price(tf);
VolumeByMargin tVol(riskPercent, symbol);
PositionStore positionStore(magicNumber, symbol);
Time time;
OrderHistory orderHistory(magicNumber);
Position position(symbol);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

input int atrMinPips;
input int pricePeriod;
input double coreRange;
input double tpTopCoef, slTopCoef;
input double tpCoreCoef, slCoreCoef;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CiADX adx;
CiATR atr;
int OnInit() {
   EventSetTimer(eventTimer);

   adx.Create(symbol, adxTf, 14);
   adx.BufferResize(3);
   atr.Create(symbol, tf, 14);
   atr.BufferResize(1);

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   time.Refresh();
   positionStore.Refresh();

   if(!CheckMarketOpen() || !CheckEquityThereShold(equityThereShold) || orderHistory.wasOrderInTheSameBar(symbol, PERIOD_H1)) {
      return;
   }

   if(Spread(symbol) > spreadLimit * pips ) {
      return;
   }


   atr.Refresh();
   adx.Refresh();

   double atr0 = atr.Main(0);
   if(atr0 < atrMinPips * pips) return;

   double top = price.Highest(symbol, 0, pricePeriod);
   double bottom = price.Lowest(symbol, 0, pricePeriod);
   double current = price.At(symbol, 0).close;
   double gap = top - bottom;
   double perB = (current - bottom) / gap;


   double bid = Bid(symbol);

   double tp, sl;
   double range = atr0;

   bool buyCondition = adx.Main(0) > adx.Main(1) && adx.Main(1) > adx.Main(2)
                       && adx.Plus(0) > 20 && adx.Plus(0) > adx.Minus(0);
   if(buyCondition) {
      double ask = Ask(symbol);

      if(perB < 0.5 - coreRange) {
         tp = ask + atr0 * tpTopCoef;
         sl = bottom - atr0 * slTopCoef;
      } else if(perB > 0.5 - coreRange && perB < 0.5 + coreRange) {
         tp = ask - atr0 * tpCoreCoef;
         sl = bottom + gap * coreRange - atr0 * slCoreCoef;
      }

      tradeRequest tR = {symbol, magicNumber, ORDER_TYPE_BUY, ask, sl, tp};

      if(position.IsAnyPositionInRange(symbol, positionStore.buyTickets, range)) {
         return;
      }

      tVol.CalcurateVolume(tR);
      trade.OpenPosition(tR);
   }

   bool sellCondition = adx.Main(0) > adx.Main(1) && adx.Main(1) > adx.Main(2)
                        && adx.Minus(0) > 20 && adx.Minus(0) > adx.Plus(0);
   if(sellCondition) {
      double bid = Bid(symbol);
      if(perB > 0.5 + coreRange) {
         tp = bid - atr0 * tpTopCoef;
         sl = top + atr0 * slTopCoef;
      } else if(perB > 0.5 - coreRange && perB < 0.5 + coreRange) {
         tp = bid - atr0 * tpCoreCoef;
         sl = top - gap * coreRange + atr0 * slCoreCoef;
      }

      tradeRequest tR = {symbol, magicNumber, ORDER_TYPE_SELL, bid, sl, tp};

      if(position.IsAnyPositionInRange(symbol, positionStore.sellTickets, range)) {
         return;
      }

      tVol.CalcurateVolume(tR);
      trade.OpenPosition(tR);

   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void buyTrade(tradeRequest &tR, double range, PositionStore &positionStore, Position &position, VolumeByMargin &tVol) {
   if(position.IsAnyPositionInRange(tR.symbol, positionStore.buyTickets, range)) {
      return;
   }
   tVol.CalcurateVolume(tR);
   trade.OpenPosition(tR);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void sellTrade(tradeRequest &tR, double range) {
   if(position.IsAnyPositionInRange(tR.symbol, positionStore.sellTickets, range)) {
      return;
   }
   tVol.CalcurateVolume(tR);
   trade.OpenPosition(tR);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double OnTester() {
   Optimization optimization;
   return optimization.Custom2();
}
//+------------------------------------------------------------------+
