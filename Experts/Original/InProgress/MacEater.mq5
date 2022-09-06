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
input optimizedTimeframes timeFrame, macdLongTimeframe, atrTimeframe;
input ENUM_APPLIED_PRICE appliedPrice;
ENUM_TIMEFRAMES tf = convertENUM_TIMEFRAMES(timeFrame);
ENUM_TIMEFRAMES atrTf = convertENUM_TIMEFRAMES(atrTimeframe);
ENUM_TIMEFRAMES macdLongTf = convertENUM_TIMEFRAMES(macdLongTimeframe);
input double tpCoef, slCoef;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

string symbol = _Symbol;
double pips = Pips(symbol);
Trade trade(magicNumber);
Price price(tf);
VolumeByRisk tVol(riskPercent, symbol);
PositionStore positionStore(magicNumber, symbol);
Time time;
OrderHistory orderHistory(magicNumber);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input int atrMinVal;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CiMACD longMacd, shortMacd;
CiATR atr;
int OnInit() {
   EventSetTimer(eventTimer);

   longMacd.Create(_Symbol, macdLongTf, 12, 26, 9, appliedPrice);
   longMacd.BufferResize(3);

   shortMacd.Create(_Symbol, tf, 12, 26, 9, appliedPrice);
   shortMacd.BufferResize(3);

   atr.Create(_Symbol, atrTf, 14);
   atr.BufferResize(1);

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {

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

   if(!CheckMarketOpen() || !CheckEquityThereShold(equityThereShold) || orderHistory.wasOrderInTheSameBar(_Symbol, tf)) {
      return;
   }

   if(SymbolInfoInteger(Symbol(), SYMBOL_SPREAD) > spreadLimit) {
      return;
   }

   double longHistogram[2];
   double shortHistogram[2];
   for(int i = 0; i < 2; i++) {
      longHistogram[i] = longMacd.Main(i) - longMacd.Signal(i);
      shortHistogram[i] = shortMacd.Main(i) - shortMacd.Signal(i);
   };

   atr.Refresh();
   longMacd.Refresh();
   shortMacd.Refresh();
   
   double atr0 = atr.Main(0);

   if(atr0 < atrMinVal * pips) return;

   bool buyCondition = longHistogram[0] > 0 && longMacd.Main(0) > 0
                       && shortHistogram[1] < 0 && shortHistogram[0] > 0
                       && shortMacd.Main(0) < 0;
   bool sellCondition = longHistogram[0] < 0 && longMacd.Main(0) < 0
                        && shortHistogram[1] > 0 && shortHistogram[0] < 0
                        && shortMacd.Main(0) > 0;

   tradeRequest tR;

   if(buyCondition) {
      double ask = Ask(symbol);
      double tp = ask + atr0 * tpCoef;
      double sl = ask + atr0 * slCoef;
      tradeRequest tR = {symbol, magicNumber, ORDER_TYPE_BUY, ask, sl, tp};

      if(positionStore.buyTickets.Total() < positionTotal && tVol.CalcurateVolume(tR)) {
         trade.OpenPosition(tR);
      }
   } else if(sellCondition) {
      double bid = Bid(symbol);
      double tp = bid - atr0 * tpCoef;
      double sl = bid + atr0 * slCoef;
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
