//+------------------------------------------------------------------+
//|                                                  NewTemplate.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "2.04"
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
#resource "\\Indicators\\SimpleCoreRanger_Indicator.ex5" //include the indicator in your file for convenience

int eventTimer = 60; // The frequency of OnTimer
input ulong magicNumber = 98351;
int stopEquity = 0;
int stopMarginLevel = 0;
int stopDrawDownPer = 100;
int spreadLimit = 99999999;
double risk = 0;
input double lot = 0.1;
ENUM_TIMEFRAMES tf = PERIOD_MN1;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Trade trade(magicNumber);
Price price(tf);
Time time;
OrderHistory orderHistory(magicNumber);

input uint pricePeriod = 10;
input double noTradeCoreRange = 0.3;
input uint positionHalf = 31;
input uint minTP = 35;
input uint maxTP = 140;
int sl = 0;

string symbol1 = _Symbol;
input string symbol2 = "USDCHF";
input string symbol3 = "AUDNZD";
Logger logger("");

int symbol1Indicator, symbol2Indicator, symbol3Indicator;
int OnInit() {
   EventSetTimer(eventTimer);

   bool isCustom;
   if(symbol2 != "" && SymbolExist(symbol2, isCustom) == false) {
      Alert( StringFormat("symbol2:'%s' does not exist. Please set the correct symbol name. you can check it on Market Watch.", symbol2));
      return (INIT_PARAMETERS_INCORRECT);
   }

   if(symbol3 != "" && SymbolExist(symbol3, isCustom) == false) {
      Alert( StringFormat("symbol3:'%s' does not exist. Please set the correct symbol name. you can check it on Market Watch.", symbol3));
      return (INIT_PARAMETERS_INCORRECT);
   }

   string symbols[] = {symbol1, symbol2, symbol3};
   for (int i = 0; i < ArraySize(symbols); i++) {
      int barMaxCount = iBars(symbols[i], tf);
      if(pricePeriod > barMaxCount) {
         Alert( StringFormat("please set pricePeriod lower than %i(maximum number of bars for calculations) and set timeframe Monthly", barMaxCount));
         return(INIT_PARAMETERS_INCORRECT);
      }
   };
   if(pricePeriod <= 0) {
      Alert("Please set a value greater than 0 for pricePeriod");
      return (INIT_PARAMETERS_INCORRECT);
   }

   if(noTradeCoreRange > 0.5) {
      Alert("Please set a value 0.5 or less for noTradeCoreRange");
      return (INIT_PARAMETERS_INCORRECT);
   }

   if(lot <= 0) {
      Alert("Please set a value greater than 0 for lot or risk");
      return (INIT_PARAMETERS_INCORRECT);
   }

   symbol1Indicator = iCustom(symbol1, tf, "::Indicators\\SimpleCoreRanger_Indicator.ex5", noTradeCoreRange, pricePeriod);
   symbol2Indicator = iCustom(symbol2, tf, "::Indicators\\SimpleCoreRanger_Indicator.ex5", noTradeCoreRange, pricePeriod);
   symbol3Indicator = iCustom(symbol3, tf, "::Indicators\\SimpleCoreRanger_Indicator.ex5", noTradeCoreRange, pricePeriod);

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   if(minTP > maxTP) {
      Alert("Do not set minTP to a value greater than maxTP");
      return;
   }

   if(!CheckMarketOpen() || !CheckEquity(stopEquity, logger) || !CheckMarginLevel(stopMarginLevel, logger) || !CheckDrawDownPer(stopDrawDownPer, logger)) return;

   makeTrade(symbol1, symbol1Indicator);
   makeTrade(symbol2, symbol2Indicator);
   makeTrade(symbol3, symbol3Indicator);
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
void makeTrade(string symbol, int indicator) {
   if(symbol == "") {
      return;
   }

   PositionStore positionStore(magicNumber, symbol);
   positionStore.Refresh();
   Logger logger(symbol);

   double pips = Pips(symbol);
   Position position(symbol);

   if(orderHistory.wasOrderInTheSameBar(symbol, PERIOD_H1)) {
      return;
   }

   double spread = Spread(symbol);
   if( spread > spreadLimit * pips) {
      return;
   }

   double highest[], lowest[], coreHighest[], coreLowest[];
   CopyBuffer(indicator, 0, 0, 1, highest);
   CopyBuffer(indicator, 1, 0, 1, lowest);
   CopyBuffer(indicator, 2, 0, 1, coreHighest);
   CopyBuffer(indicator, 3, 0, 1, coreLowest);

   double current = price.At(symbol, 0).close;
   double gap = highest[0] - lowest[0];

   double tpAdd = gap * (1 - noTradeCoreRange * 2)  / positionHalf;

   if(tpAdd < minTP * pips) tpAdd = minTP * pips;
   if(tpAdd > maxTP * pips) tpAdd = maxTP * pips;

   double range = tpAdd;
   bool sellCondition = current > coreHighest[0];
   bool buyCondition = current < coreLowest[0];
   VolumeByMargin tVol(risk, symbol);
   if(buyCondition) {
      double ask = Ask(symbol);
      if(position.IsAnyPositionInRange(symbol, positionStore.buyTickets, range)) {
         return;
      }
      double stopLoss = sl == 0 ? 0 : ask - sl * pips;
      double tp = ask + tpAdd;
      tradeRequest tR = {symbol, magicNumber, ORDER_TYPE_BUY, ask, stopLoss, tp};

      lot > 0 ? tR.volume = lot : tVol.CalcurateVolume(tR, logger);
      trade.OpenPosition(tR, logger);
   }
   if(sellCondition) {
      double bid = Bid(symbol);
      if(position.IsAnyPositionInRange(symbol, positionStore.sellTickets, range)) {
         return;
      }
      double stopLoss = sl == 0 ? 9999999 : bid + sl * pips;
      double tp = bid - tpAdd;
      tradeRequest tR = {symbol, magicNumber, ORDER_TYPE_SELL, bid, stopLoss, tp};

      lot > 0 ? tR.volume = lot : tVol.CalcurateVolume(tR, logger);
      trade.OpenPosition(tR, logger);
   }
}
//+------------------------------------------------------------------+
