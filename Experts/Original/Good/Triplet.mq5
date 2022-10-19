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
input double lot = 0;
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
input double coreRange = 0.2;
input int positionHalf;
input int minTP, maxTP;

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
   if(minTP > maxTP) {
      return;
   }

   if(!CheckMarketOpen() || !CheckEquityThereShold(equityThereShold)) return;

   makeTrade(symbol1);
   makeTrade(symbol2);
   makeTrade(symbol3);
// NZDCAD
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double OnTester() {
   Optimization optimization;
   if(!optimization.CheckResultValid()) return 0;

   double ddPercent = optimization.equityDdrelPercent > optimization.balanceDdrelPercent ? optimization.equityDdrelPercent : optimization.balanceDdrelPercent;

   double profitFactor = 1 / ddPercent;
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

   double spread = Spread(symbol);
   if( spread > spreadLimit * pips) {
      return;
   }

   double top = price.Highest(symbol, 0, pricePeriod);
   double bottom = price.Lowest(symbol, 0, pricePeriod);
   double current = price.At(symbol, 0).close;
   double gap = top - bottom;
   double perB = (current - bottom) / gap;


   bool sellCondition = perB > 0.5 + coreRange;
   bool buyCondition = perB < 0.5 - coreRange;

   double tpAdd = gap * (1 - coreRange * 2)  / positionHalf;

   if(tpAdd < minTP * pips) tpAdd = minTP * pips;
   if(tpAdd > maxTP * pips) tpAdd = maxTP * pips;

   double range = tpAdd;

   VolumeByMargin tVol(risk, symbol);
   
   if(buyCondition) {
      double ask = Ask(symbol);
      if(position.IsAnyPositionInRange(symbol, positionStore.buyTickets, range)) {
         return;
      }
      double sl = 0;
      double tp = ask + tpAdd;
      tradeRequest tR = {symbol, magicNumber, ORDER_TYPE_BUY, ask, sl, tp};

      lot > 0 ? tR.volume = lot : tVol.CalcurateVolume(tR);
      trade.OpenPosition(tR);
   }
   if(sellCondition) {
      double bid = Bid(symbol);
      if(position.IsAnyPositionInRange(symbol, positionStore.sellTickets, range)) {
         return;
      }
      double sl = 999;
      double tp = bid - tpAdd;
      tradeRequest tR = {symbol, magicNumber, ORDER_TYPE_SELL, bid, sl, tp};

      lot > 0 ? tR.volume = lot : tVol.CalcurateVolume(tR);
      trade.OpenPosition(tR);
   }
}
//+------------------------------------------------------------------+
