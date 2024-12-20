//+------------------------------------------------------------------+
//|                                                  NewTemplate.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "3.3"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
#include <Ramune\OptimizedParameter.mqh>
#include <Ramune\Optimization.mqh>
#include <Ramune\Trade\Trade.mqh>
#include <Ramune\Trade\VolumeByMargin.mqh>
#include <Ramune\Price.mqh>
#include <Ramune\Position\PositionStore.mqh>
#include <Ramune\Position\Position.mqh>
#include <Ramune\Time.mqh>
#include <Ramune\OrderHistory.mqh>
#include <Indicators\TimeSeries.mqh>
#include <Indicators\Oscilators.mqh>
#include <Indicators\Trend.mqh>
#include <Indicators\BillWilliams.mqh>

int eventTimer = 60; // The frequency of OnTimer
input ulong magicNumber = 98352;
input int stopEquity = 0;
input int stopMarginLevel = 500;
input int stopDrawDownPer = 20;
input int spreadLimit = 20;
input double risk = 2.5;
input double lot = 0;
ENUM_TIMEFRAMES tf = PERIOD_MN1;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Trade trade(magicNumber);
Price price(tf);
Time time;
OrderHistory orderHistory(magicNumber);

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CiATR atrEURGBP, atrAUDNZD, atrUSDCHF;

input uint pricePeriod = 34;
input double noTradeCoreRange = 0.16;
input uint positionHalf = 31;
input uint minTP = 95;
input uint maxTP = 271;
input uint sl = 0;

string symbol1 = _Symbol;
input string symbol2 = "USDCHF-";
input string symbol3 = "AUDNZD-";
input double upperLimit1, upperLimit2, upperLimit3 = 0;
input double lowerLimit1, lowerLimit2, lowerLimit3 = 0;
Logger logger("");
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   EventSetTimer(eventTimer);

   if(AccountInfoInteger(ACCOUNT_MARGIN_MODE) == ACCOUNT_MARGIN_MODE_RETAIL_NETTING) {
      Alert("This EA does not work on Netting Mode. Use Hedging Mode");
      return(INIT_FAILED);
   }

   if(_Period != PERIOD_MN1) {
      Alert("please set timeframe Monthly");
      return(INIT_FAILED);
   }

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
         Alert( StringFormat("please set pricePeriod lower than %i(maximum number of bars for calculations). If you have never display %s monthly chart, display it to load monthly data ", barMaxCount, symbols[i]));
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

   if(positionHalf <= 0) {
      Alert("Please set a value greater than 0 for positionHalf");
      return (INIT_PARAMETERS_INCORRECT);
   }

   if(lot <= 0 && risk <= 0) {
      Alert("Please set a value greater than 0 for lot or risk");
      return (INIT_PARAMETERS_INCORRECT);
   }
   if(lot > 0 && risk > 0) {
      Alert("Please set either lot or risk");
      return (INIT_PARAMETERS_INCORRECT);
   }


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

   if(!CheckMarketOpen() || !CheckEquity(stopEquity, logger) || !CheckDrawDownPer(stopDrawDownPer, logger) || !CheckMarginLevel(stopMarginLevel, logger)) return;

   makeTrade(symbol1, upperLimit1, lowerLimit1);
   makeTrade(symbol2, upperLimit2, lowerLimit2);
   makeTrade(symbol3, upperLimit3, lowerLimit3);
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
void makeTrade(string symbol, double upperLimit, double lowerLimit) {
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

   if(!CheckSpread(symbol,spreadLimit)) return;

   double top = price.Highest(symbol, 0, pricePeriod, logger);
   double bottom = price.Lowest(symbol, 0, pricePeriod, logger);
   if(top == bottom) return;
   if(top == EMPTY_VALUE || bottom == EMPTY_VALUE) {
      return;
   }

   double current = price.At(symbol, 0).close;
   double gap = top - bottom;
   double perB = (current - bottom) / gap;

   if(current > upperLimit && upperLimit != 0 ) {
      logger.Log(StringFormat("Trading was stopped :: current price(%f) is upper than upperLimit(%f)", current, upperLimit), Warning);
      return;
   }
   if(current < lowerLimit && lowerLimit != 0) {
      logger.Log(StringFormat("Trading was stopped :: current price(%f) is lower than lowerLimit(%f)", current, lowerLimit), Warning);
      return;
   }


   bool sellCondition = perB > 0.5 + noTradeCoreRange;
   bool buyCondition = perB < 0.5 - noTradeCoreRange;

   double tpAdd = gap * (1 - noTradeCoreRange * 2)  / positionHalf;

   if(tpAdd < minTP * pips) tpAdd = minTP * pips;
   if(tpAdd > maxTP * pips) tpAdd = maxTP * pips;

   double range = tpAdd;

   VolumeByMargin tVol(risk, symbol);

   string comment = "47546:TripleBullet_EA";
   if(buyCondition) {
      double ask = Ask(symbol);
      if(position.IsAnyPositionInRange(symbol, positionStore.buyTickets, range)) {
         return;
      }
      double stopLoss = sl == 0 ? 0 : ask - sl * pips;
      double tp = ask + tpAdd;
      tradeRequest tR = {symbol, magicNumber, ORDER_TYPE_BUY, ask, stopLoss, tp};

      lot > 0 ? tR.volume = lot : tVol.CalcurateVolume(tR, logger);
      trade.OpenPosition(tR, logger, comment);
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
      trade.OpenPosition(tR, logger, comment);
   }
}
//+------------------------------------------------------------------+
