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
#include <MyPkg\Trade\VolumeByRisk.mqh>
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
#include <Indicators\Volumes.mqh>

int eventTimer = 60; // The frequency of OnTimer
input ulong magicNumber = 21984;
input int equityThereShold = 1500;
input int riskPercent = 2;
input int positionTotal = 1;
input int whenToCloseOnFriday = 23;
input int spreadLimit = 999;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string symbol = _Symbol;
Trade trade(magicNumber);
Price price(PERIOD_MN1);
PositionStore positionStore(magicNumber,symbol);
Position position(symbol);
Time time;
OrderHistory orderHistory(magicNumber);
VolumeByRisk tVol(riskPercent, symbol);
double pips = Pips(symbol);

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CiBands bLong, bShort;
Appointed trailing(symbol);


input optimizedTimeframes timeFrame, longTimeframe;
input int longDeviation,shortDeviation;
input int rangePips;
ENUM_TIMEFRAMES tf = convertENUM_TIMEFRAMES(timeFrame);
ENUM_TIMEFRAMES longTf = convertENUM_TIMEFRAMES(timeFrame);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   EventSetTimer(eventTimer);
   bLong.Create(symbol, longTf, 20, 0, longDeviation, PRICE_TYPICAL);
   bLong.BufferResize(3);
   bShort.Create(symbol, tf, 20, 0, shortDeviation, PRICE_TYPICAL);
   bShort.BufferResize(3);

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   time.Refresh();
   positionStore.Refresh();

   bLong.Refresh();
   bShort.Refresh();
   double base = bLong.Base(0);



   // don't trade before 2 hours from market close
   if(time.CheckTimeOver(FRIDAY, whenToCloseOnFriday - 2)) {
      if(time.CheckTimeOver(FRIDAY, whenToCloseOnFriday - 1)) {
         trade.ClosePositions(positionStore.buyTickets);
         trade.ClosePositions(positionStore.sellTickets);
      }
      return;
   }

   if(!CheckMarketOpen() || !CheckEquityThereShold(equityThereShold) || orderHistory.wasOrderInTheSameBar(_Symbol, tf)) {
      return;
   }

   if(SymbolInfoInteger(Symbol(), SYMBOL_SPREAD) > spreadLimit) {
      return;
   }

   for(int i = 0; i < 3; i++) {
      bool shortInLong = bLong.Upper(i) > bShort.Upper(i)
                         && bLong.Lower(i) < bShort.Lower(i);
      if(!shortInLong) return;
   }

   MqlRates price0 = price.At(symbol, 0);
   bool buyCondition = price0.close > base;
   bool sellCondition = price0.close < base;

   tradeRequest tR;

   double tp = base;
   double range = rangePips * pips;
   if(buyCondition) {
      if(position.IsAnyPositionInRange(symbol, positionStore.buyTickets, range)) {
         return;
      }

      double ask = Ask(symbol);
      double sl = bLong.Lower(0);
      tradeRequest tR = {symbol, magicNumber, ORDER_TYPE_BUY, ask, sl, tp};

      if(positionStore.buyTickets.Total() < positionTotal && tVol.CalcurateVolume(tR)) {
         trade.OpenPosition(tR);
      }
   } else if(sellCondition) {
      if(position.IsAnyPositionInRange(symbol, positionStore.buyTickets, range)) {
         return;
      }
      double bid = Bid(symbol);
      double sl = bLong.Upper(0);
      tradeRequest tR = {symbol, magicNumber, ORDER_TYPE_SELL, bid, sl, tp};

      if(positionStore.sellTickets.Total() < positionTotal && tVol.CalcurateVolume(tR)) {
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
