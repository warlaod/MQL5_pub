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
input optimizedTimeframes longTimeframe, shortTimeframe, atrTimeframe;
ENUM_TIMEFRAMES tf = convertENUM_TIMEFRAMES(shortTimeframe);
ENUM_TIMEFRAMES longTf = convertENUM_TIMEFRAMES(longTimeframe);
ENUM_TIMEFRAMES atrTf = convertENUM_TIMEFRAMES(atrTimeframe);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

string symbol = _Symbol;
double pips = Pips(symbol);
Trade trade(magicNumber);
Price price(tf);
Volume tVol(riskPercent, _Symbol);
PositionStore positionStore(magicNumber);
Time time;
OrderHistory orderHistory(magicNumber);

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Appointed trailing(symbol);
CiMACD macdLong, macdShort;
CiATR atr;
input int slPips, stopPeriod, atrPeriod;
input double slCoef, tpCoef;
input bool longOnly;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   EventSetTimer(eventTimer);

   macdLong.Create(symbol, longTf, 12, 26, 9, PRICE_CLOSE);
   macdLong.BufferResize(3);
   macdShort.Create(symbol, tf, 12, 26, 9, PRICE_CLOSE);
   macdShort.BufferResize(3);

   atr.Create(symbol, atrTf, atrPeriod);
   atr.BufferResize(1);

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   if (longTf <= tf)
      return;
      
   time.Refresh();
   positionStore.Refresh();

   // don't trade before 2 hours from market close
   if(time.CheckTimeOver(FRIDAY, whenToCloseOnFriday - 2)) {
      if(time.CheckTimeOver(FRIDAY, whenToCloseOnFriday - 1)) {
         trade.ClosePositions(positionStore.buyTickets);
         trade.ClosePositions(positionStore.sellTickets);
      }
      return;
   }

   if(!CheckMarketOpen() || !CheckEquityThereShold(equityThereShold) || orderHistory.wasOrderInTheSameBar(symbol, tf)) {
      return;
   }

   if(SymbolInfoInteger(Symbol(), SYMBOL_SPREAD) > spreadLimit) {
      return;
   }

   macdLong.Refresh();
   macdShort.Refresh();

   double LongHistogram[2];
   double ShortHistogram[2];
   for(int i = 0; i < 2; i++) {
      LongHistogram[i] = macdLong.Main(i) - macdShort.Signal(i);
      ShortHistogram[i] = macdShort.Main(i) - macdShort.Signal(i);
   }
   bool buyCondition = LongHistogram[0] > 0 && macdLong.Main(0) > 0
                       && ShortHistogram[1] < 0 && ShortHistogram[0] > 0
                       && macdShort.Main(0) < 0;

   bool sellCondition = LongHistogram[0] < 0 && macdLong.Main(0) < 0
                        && ShortHistogram[1] > 0 && ShortHistogram[0] < 0
                        && macdShort.Main(0) > 0;


   tradeRequest tR;

   atr.Refresh();
   double atr0 = atr.Main(0);
   if(buyCondition && longOnly) {
      double ask = Ask(symbol);
      double sl = ask - atr0 * slCoef;
      double tp = ask + atr0 * tpCoef;
      tradeRequest tR = {symbol, magicNumber, ORDER_TYPE_BUY, ask, sl, tp};

      if(positionStore.buyTickets.Total() < positionTotal && tVol.CalcurateVolume(tR)) {
         trade.OpenPosition(tR);
      }
   }
   if(sellCondition || !longOnly) {
      double bid = Bid(symbol);
      double sl = bid + atr0 * slCoef;
      double tp = bid - atr0 * tpCoef;
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