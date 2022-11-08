//+------------------------------------------------------------------+
//|                                                  NewTemplate.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.10"
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
int stopEquity = 0;
int stopMarginLevel = 0;
double risk = 0;
int spreadLimit = 9999999;
input double lot = 0.1;
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

input int pricePeriod = 5;
input double coreRange = 0.2;
input int positionHalf = 1;
input int positionCore = 1;
input int minTP = 0;
input int maxTP = 100;

string symbol1 = _Symbol;
CiADX adx;
int OnInit() {
   EventSetTimer(eventTimer);
   
   if(minTP > maxTP){
      Alert("Do not set minTP to a value greater than maxTP");
      return (INIT_PARAMETERS_INCORRECT);
   }
   if(pricePeriod <= 0){
      Alert("Please set a value greater than 0 for pricePeriod");
      return (INIT_PARAMETERS_INCORRECT);
   }

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   Logger logger("");
   if(!CheckMarketOpen() || !CheckEquity(stopEquity, logger) || !CheckMarginLevel(stopMarginLevel, logger)) return;

   makeTrade(symbol1);
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
   if(minTP > maxTP) {
      return;
   }
   Logger logger(symbol);
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

   double top = price.Highest(symbol, 0, pricePeriod, logger);
   double bottom = price.Lowest(symbol, 0, pricePeriod, logger);
   if(top == bottom) return;
   if(top == EMPTY_VALUE || bottom == EMPTY_VALUE) {
      return;
   }

   double current = price.At(symbol, 0).close;
   double perB = (current - bottom) / (top - bottom);
   double gap = top - bottom;

   bool sellCondition = perB > 0.5 - coreRange;
   bool buyCondition = perB < 0.5 + coreRange;


   double tpAdd;
   if(0.5 - coreRange < perB && 0.5 + coreRange > perB && positionCore > 0) {
      tpAdd = gap * coreRange * 2 / positionCore;
   } else if(positionHalf > 0) {
      tpAdd = gap * (1 - coreRange * 2)  / positionHalf;
   }

   if(tpAdd < minTP * pips) {
      tpAdd = minTP * pips;
   }
   if(tpAdd > maxTP * pips) {
      tpAdd = maxTP * pips;
   }

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

      lot > 0 ? tR.volume = lot : tVol.CalcurateVolume(tR, logger);
      trade.OpenPosition(tR, logger);
   }
   if(sellCondition) {
      double bid = Bid(symbol);
      if(position.IsAnyPositionInRange(symbol, positionStore.sellTickets, range)) {
         return;
      }
      double sl = 999;
      double tp = bid - tpAdd;
      tradeRequest tR = {symbol, magicNumber, ORDER_TYPE_SELL, bid, sl, tp};

      lot > 0 ? tR.volume = lot : tVol.CalcurateVolume(tR, logger);
      trade.OpenPosition(tR, logger);
   }
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
