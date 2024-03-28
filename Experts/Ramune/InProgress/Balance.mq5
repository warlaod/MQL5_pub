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
#include <Ramune\OptimizedParameter.mqh>
#include <Ramune\Optimization.mqh>
#include <Ramune\Trade\Trade.mqh>
#include <Ramune\Trade\Volume.mqh>
#include <Ramune\Price.mqh>
#include <Ramune\Position\PositionStore.mqh>
#include <Ramune\Position\Position.mqh>
#include <Ramune\Time.mqh>
#include <Ramune\Trailing\Appointed.mqh>
#include <Ramune\OrderHistory.mqh>
#include <Indicators\TimeSeries.mqh>
#include <Indicators\Oscilators.mqh>
#include <Indicators\Trend.mqh>
#include <Indicators\BillWilliams.mqh>
#include <Indicators\Volumes.mqh>

int eventTimer = 60; // The frequency of OnTimer
input ulong magicNumber = 21984;
input int equityThereShold = 1500;
input int spreadLimit = 999;
input optimizedTimeframes timeFrame;
ENUM_TIMEFRAMES tf = convertENUM_TIMEFRAMES(timeFrame);
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
CiATR atrEURGBP, atrAUDNZD, atrUSDCHF;

input int pricePeriod;
input double coreLimit, topLimit;
input double tpCoef,rangeCoef;
input int minTPPips, maxTPPips;
input int minRangePips;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   if (minTPPips > maxTPPips || topLimit + coreLimit >= 0.5)
      return(INIT_PARAMETERS_INCORRECT);
   EventSetTimer(eventTimer);

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   time.Refresh();
   positionStore.Refresh();

   if(!CheckMarketOpen() || !CheckEquityThereShold(equityThereShold)) return;

   makeTrade("AUDNZD", tpCoef);
   makeTrade("EURGBP", tpCoef);
   makeTrade("USDCHF", tpCoef);
   // NZDCAD
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double OnTester() {
   Optimization optimization;
   return optimization.Custom();
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void makeTrade(string symbol, double tpCoef) {
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

   bool sellCondition = perB > 0.5 + coreLimit
                        && perB < 1 - topLimit;

   bool buyCondition = perB < 0.5 - coreLimit
                       && perB > topLimit;

   Volume tVol(5, symbol);
   double distance = top-bottom;
   double tpAdd = distance * tpCoef;
   if(tpAdd > maxTPPips * pips){
      tpAdd = maxTPPips * pips;
   }
   if(tpAdd < minTPPips * pips){
      tpAdd = minTPPips * pips;
   }

   double range = distance * rangeCoef;
   if(range < minRangePips * pips){
      range = minRangePips * pips;
   }
   if(buyCondition) {
      double ask = Ask(symbol);
      if(position.IsAnyPositionInRange(symbol, positionStore.buyTickets, range)) {
         return;
      }
      double sl = 0;
      double tp = ask + tpAdd;
      tradeRequest tR = {symbol, magicNumber, ORDER_TYPE_BUY, ask, sl, tp};

      tVol.CalcurateVolumeByRisk(tR,5);
      trade.OpenPosition(tR);
   } else if(sellCondition) {
      double bid = Bid(symbol);
      if(position.IsAnyPositionInRange(symbol, positionStore.sellTickets, range)) {
         return;
      }
      double sl = 999;
      double tp = bid - tpAdd;
      tradeRequest tR = {symbol, magicNumber, ORDER_TYPE_SELL, bid, sl, tp};

      tVol.CalcurateVolumeByRisk(tR,5);
      trade.OpenPosition(tR);
   }
}
//+------------------------------------------------------------------+
