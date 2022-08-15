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
#include <Indicators\Volumes.mqh>

int eventTimer = 60; // The frequency of OnTimer
input ulong magicNumber = 21984;
input int equityThereShold = 1500;
input double risk = 5;
input int pricePeriod;
input int spreadLimit = 999;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Trade trade(magicNumber);
Price price(PERIOD_MN1);
Time time;
OrderHistory orderHistory(magicNumber);

input double tpCoef, rangeCoef;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   EventSetTimer(eventTimer);

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double requiredMargin1, requiredMargin2;
input string symbol1, symbol2;
PositionStore psSymbol1(magicNumber, symbol1);
PositionStore psSymbol2(magicNumber, symbol2);
void OnTick() {
   if(!CheckMarketOpen() || !CheckEquityThereShold(equityThereShold)) return;

   time.Refresh();
   psSymbol1.Refresh();
   psSymbol2.Refresh();

   makeTrade(symbol1, tpCoef, psSymbol1);
   makeTrade(symbol2, tpCoef, psSymbol2);



}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double OnTester() {
   Optimization optimization;
   return optimization.ViceVersa();
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void makeTrade(string symbol, double tpPips, PositionStore &positionStore) {

   if(symbol == "") {
      return;
   }

   double pips = Pips(symbol);
   Position position(symbol);


   if(orderHistory.wasOrderInTheSameBar(symbol, PERIOD_H1)) {
      return;
   }

   if(Spread(symbol) > spreadLimit * pips) {
      return;
   }

   double top = price.Highest(symbol, 0, pricePeriod);
   double bottom = price.Lowest(symbol, 0, pricePeriod);
   double current = price.At(symbol, 0).close;
   double perB = (current - bottom) / (top - bottom);

   double distance = top - bottom;
   double tpAdd = distance * tpCoef;
   double range = distance * rangeCoef;

   bool buyCondition = true;
   VolumeByMargin tVol(risk, symbol);


   if(buyCondition) {
      double ask = Ask(symbol);
      if(position.IsAnyPositionInRange(symbol, positionStore.buyTickets, range)) {
         return;
      }
      double sl = 0;
      double tp = ask + tpAdd;
      tradeRequest tR = {symbol, magicNumber, ORDER_TYPE_BUY, ask, sl, tp};

      tVol.CalcurateVolume(tR);

      double maxVol = SymbolInfoDouble(tR.symbol, SYMBOL_VOLUME_MAX);

      while(tR.volume > maxVol) {
         tradeRequest maxTr = tR;
         maxTr.volume = maxVol;
         trade.OpenPosition(maxTr);
         tR.volume -= maxVol;
      }

      trade.OpenPosition(tR);

   }
}
//+------------------------------------------------------------------+
