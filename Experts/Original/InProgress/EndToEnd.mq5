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
input int risk = 5;
input int positionTotal = 1;
input int whenToCloseOnFriday = 23;
input int spreadLimit = 999;
input optimizedTimeframes timeFrame, forceTimeframe;
ENUM_TIMEFRAMES tf = convertENUM_TIMEFRAMES(timeFrame);
ENUM_TIMEFRAMES ftf = convertENUM_TIMEFRAMES(forceTimeframe);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Trade trade(magicNumber);
Price price(PERIOD_MN1);
PositionStore positionStore(magicNumber);
Time time;
OrderHistory orderHistory(magicNumber);

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CiATR atrEURUSD, atrUSDJPY, atrEURJPY;
CiForce fEURUSD, fUSDJPY, fEURJPY;
input int atrPeriod, pricePeriod, slPips;
input double middleLimit, topLimit;
input double tpCoef;
input int minTPPips, maxTPPips;
input int forcePeriod;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   if (minTPPips > maxTPPips)
      return(INIT_PARAMETERS_INCORRECT);
   EventSetTimer(eventTimer);
   atrEURUSD.Create("EURUSD", tf, atrPeriod);
   atrEURUSD.BufferResize(1);

   atrEURJPY.Create("EURJPY", tf, atrPeriod);
   atrEURJPY.BufferResize(1);

   atrUSDJPY.Create("USDJPY", tf, atrPeriod);
   atrUSDJPY.BufferResize(1);

   fEURUSD.Create("EURUSD", ftf, forcePeriod, MODE_EMA, VOLUME_TICK);
   fEURUSD.BufferResize(2);

   fEURJPY.Create("EURJPY", ftf, forcePeriod, MODE_EMA, VOLUME_TICK);
   fEURJPY.BufferResize(2);

   fUSDJPY.Create("USDJPY", ftf, forcePeriod, MODE_EMA, VOLUME_TICK);
   fUSDJPY.BufferResize(2);

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   time.Refresh();
   positionStore.Refresh();

   if(!CheckMarketOpen() || !CheckEquityThereShold(equityThereShold)) return;

   makeTrade("EURJPY", atrEURJPY, fEURJPY);
   makeTrade("USDJPY", atrUSDJPY, fUSDJPY);
   makeTrade("EURUSD", atrEURUSD, fEURUSD);
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
void makeTrade(string symbol, CiATR &atr, CiForce &force) {
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

   force.Refresh();
   double force0 = force.Main(0);
   double force1 = force.Main(1);
   bool sellCondition = perB > 0.5 + middleLimit
                        && perB < 1 - topLimit
                        && force0 < 0
                        && force0 < force1;

   bool buyCondition = perB < 0.5 - middleLimit
                       && perB > topLimit
                       && force0 > 0
                       && force0 > force1;

   atr.Refresh();
   Volume tVol(5, symbol);
   double range = atr.Main(0) * tpCoef;
   if(range / pips < minTPPips) {
      range = minTPPips * pips;
   }
   if(range / pips > maxTPPips) {
      range = maxTPPips * pips;
   }

   if(buyCondition) {
      double ask = Ask(symbol);
      if(position.IsAnyPositionInRange(symbol, positionStore.buyTickets, range)) {
         return;
      }
      double sl = 0;
      double tp = ask + range;
      tradeRequest tR = {symbol, magicNumber, ORDER_TYPE_BUY, ask, sl, tp};

      tVol.CalcurateVolumeByRisk(tR, risk);
      trade.OpenPosition(tR);


   } else if(sellCondition) {
      double bid = Bid(symbol);
      if(position.IsAnyPositionInRange(symbol, positionStore.sellTickets, range)) {
         return;
      }
      double sl = 999;
      double tp = bid - range;
      tradeRequest tR = {symbol, magicNumber, ORDER_TYPE_SELL, bid, sl, tp};

      tVol.CalcurateVolumeByRisk(tR, risk);
      trade.OpenPosition(tR);


   }
}
//+------------------------------------------------------------------+
