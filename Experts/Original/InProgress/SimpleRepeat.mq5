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
#include <MyPkg\Trailing\Appointed.mqh>
#include <MyPkg\OrderHistory.mqh>
#include <Indicators\TimeSeries.mqh>
#include <Indicators\Oscilators.mqh>
#include <Indicators\Trend.mqh>
#include <Indicators\BillWilliams.mqh>

int eventTimer = 60; // The frequency of OnTimer
input ulong magicNumber = 21984;
input int equityThereShold = 1500;
input double risk = 5;
input int spreadLimit = 999;
optimizedTimeframes timeFrame = PERIOD_MN1;
ENUM_TIMEFRAMES tf = convertENUM_TIMEFRAMES(timeFrame);

input optimizedTimeframes indTimeframe = PERIOD_MN1;
ENUM_TIMEFRAMES indTf = convertENUM_TIMEFRAMES(indTimeframe);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Trade trade(magicNumber);
Price price(PERIOD_MN1);
Time time;
OrderHistory orderHistory(magicNumber);

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CiATR atrEURGBP, atrAUDNZD, atrUSDCHF;

input int pricePeriod, indPeriod;
input double coreRange;
input int halfPositionTotal, corePositionTotal;
input int minTP;
input double rangeCoef;

string symbol1 = _Symbol;
CiADX adx;
int OnInit() {
   EventSetTimer(eventTimer);

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {

   if(!CheckMarketOpen() || !CheckEquityThereShold(equityThereShold)) return;

   makeTrade(symbol1);
// NZDCAD
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double OnTester() {
   Optimization optimization;
   if(!optimization.CheckResultValid()) return 0;

   double profitFactor = 1 / optimization.equityDdrelPercent * MathSqrt(optimization.trades);
   double base = optimization.profit;
   double result =  base * profitFactor;
   if(optimization.profit < 0) {
      result = base / profitFactor;
   }
   return result;
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void makeTrade(string symbol) {
   PositionStore positionStore(magicNumber, symbol);
   positionStore.Refresh();

   double pips = Pips(symbol);
   Position position(symbol);

   if(orderHistory.wasOrderInTheSameBar(symbol, PERIOD_H1)) {
      return;
   }

   if(SymbolInfoInteger(symbol, SYMBOL_SPREAD) > spreadLimit) {
      return;
   }

   double top = price.Highest(symbol, 0, pricePeriod);
   double bottom = price.Lowest(symbol, 0, pricePeriod);
   double current = price.At(symbol, 0).close;
   double perB = (current - bottom) / (top - bottom);
   double gap = top - bottom;

   adx.Refresh();


   bool sellCondition = perB < 0.5 + coreRange
                        && adx.Main(0) > 20
                        && adx.Plus(0) > adx.Minus(0)
                        && adx.Plus(0) > adx.Plus(1) && adx.Plus(1) > adx.Plus(2);
   bool buyCondition = perB > 0.5 - coreRange
                       && adx.Main(0) > 20
                       && adx.Minus(0) > adx.Plus(0)
                       && adx.Minus(0) > adx.Minus(1) && adx.Minus(1) > adx.Minus(2);

   double unit;
   if(0.5 - coreRange < perB && 0.5 + coreRange > perB) {
      unit = gap * coreRange * 2 / corePositionTotal;
   } else {
      unit = gap * (1 - coreRange * 2)  / corePositionTotal;
   }

   if(unit < minTP * pips) unit = minTP * pips;

   VolumeByMargin tVol(risk, symbol);
   if(buyCondition) {
      double ask = Ask(symbol);
      if(position.IsAnyPositionInRange(symbol, positionStore.buyTickets, unit)) {
         return;
      }
      double sl = 0;
      double tp = ask + unit;
      tradeRequest tR = {symbol, magicNumber, ORDER_TYPE_BUY, ask, sl, tp};

      tVol.CalcurateVolume(tR);
      trade.OpenPosition(tR);
   } else if(sellCondition) {
      double bid = Bid(symbol);
      if(position.IsAnyPositionInRange(symbol, positionStore.sellTickets, unit)) {
         return;
      }
      double sl = 999;
      double tp = bid - unit;
      tradeRequest tR = {symbol, magicNumber, ORDER_TYPE_SELL, bid, sl, tp};

      tVol.CalcurateVolume(tR);
      trade.OpenPosition(tR);
   }
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
