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
input double risk = 4.5;
input int spreadLimit = 30;
optimizedTimeframes timeFrame = PERIOD_MN1;
ENUM_TIMEFRAMES tf = convertENUM_TIMEFRAMES(timeFrame);
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

input int pricePeriod = 36;
input double coreLimit = 0.2;
input double topLimit = 0.15;
input double tpCoef = 0.008;
input double rangeCoef = 0.074;
input int minTPPips = 10;
input int maxTPPips = 420;
input int minRangePips = 160;
input int maxRangePips = 340;

input string symbol1 = "EURGBP";
input string symbol2 = "USDCHF";
input string symbol3 = "AUDNZD";
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
void OnTick() {
   if (minTPPips > maxTPPips || topLimit + coreLimit >= 0.5 || minRangePips > maxRangePips)
      return;

   if(!CheckMarketOpen() || !CheckEquityThereShold(equityThereShold)) return;

   makeTrade(symbol1, tpCoef);
   makeTrade(symbol2, tpCoef);
   makeTrade(symbol3, tpCoef);
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
   if(symbol == "") {
      return;
   }

   PositionStore positionStore(magicNumber, symbol);
   positionStore.Refresh();

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

   bool sellCondition = perB > 0.5 + coreLimit
                        && perB < 1 - topLimit;

   bool buyCondition = perB < 0.5 - coreLimit
                       && perB > topLimit;

   VolumeByMargin tVol(risk, symbol);
   double distance = top - bottom;
   double tpAdd = distance * tpCoef;
   if(tpAdd > maxTPPips * pips) {
      tpAdd = maxTPPips * pips;
   }
   if(tpAdd < minTPPips * pips) {
      tpAdd = minTPPips * pips;
   }

   double range = distance * rangeCoef;
   if(range < minRangePips * pips) {
      range = minRangePips * pips;
   }
   if(range > maxRangePips * pips) {
      range = maxRangePips * pips;
   }
   if(buyCondition) {
      double ask = Ask(symbol);
      if(position.IsAnyPositionInRange(symbol, positionStore.buyTickets, range)) {
         return;
      }
      double sl = 0;
      double tp = ask + tpAdd;
      tradeRequest tR = {symbol, magicNumber, ORDER_TYPE_BUY, ask, sl, tp};

      tVol.CalcurateVolume(tR);
      trade.OpenPosition(tR);
   } else if(sellCondition) {
      double bid = Bid(symbol);
      if(position.IsAnyPositionInRange(symbol, positionStore.sellTickets, range)) {
         return;
      }
      double sl = 999;
      double tp = bid - tpAdd;
      tradeRequest tR = {symbol, magicNumber, ORDER_TYPE_SELL, bid, sl, tp};

      tVol.CalcurateVolume(tR);
      trade.OpenPosition(tR);
   }
}
//+------------------------------------------------------------------+
