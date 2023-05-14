//+------------------------------------------------------------------+
//|                                                  NewTemplate.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "2.01"
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
input ulong magicNumber = 21984;
int stopEquity = 0;
int stopMarginLevel = 0;
int stopDrawDownPer = 100;
double risk = 0;
int spreadLimit = 99999999;
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
int scrIndicator;
Logger logger(symbol1);
int OnInit() {
   EventSetTimer(eventTimer);

   if(minTP > maxTP) {
      Alert("Do not set minTP to a value greater than maxTP");
      return (INIT_PARAMETERS_INCORRECT);
   }
   
   int barMaxCount = Bars(_Symbol, PERIOD_CURRENT);
   if(pricePeriod > barMaxCount) {
      Alert( StringFormat("please set pricePeriod lower than %i(maximum number of bars for calculations)", barMaxCount));
      return(INIT_PARAMETERS_INCORRECT);
   }
   if(pricePeriod <= 0) {
      Alert("Please set a value greater than 0 for pricePeriod");
      return (INIT_PARAMETERS_INCORRECT);
   }
   
   if(coreRange > 0.5) {
      Alert("Please set a value 0.5 or less for coreRange");
      return (INIT_PARAMETERS_INCORRECT);
   }
   if(lot <= 0) {
      Alert("Please set a value greater than 0 for lot or risk");
      return (INIT_PARAMETERS_INCORRECT);
   }
   
   scrIndicator = iCustom(symbol1,PERIOD_MN1,"::Indicators\\SimpleCoreRanger_Indicator.ex5",coreRange,pricePeriod);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   if(!CheckMarketOpen() || !CheckEquity(stopEquity, logger) || !CheckMarginLevel(stopMarginLevel, logger) || !CheckDrawDownPer(stopDrawDownPer, logger)) return;
   makeTrade(symbol1);
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
   
   double highest[],lowest[],coreHighest[],coreLowest[];
   CopyBuffer(scrIndicator, 0, 0, 1, highest);
   CopyBuffer(scrIndicator, 1, 0, 1, lowest);
   CopyBuffer(scrIndicator, 2, 0, 1, coreHighest);
   CopyBuffer(scrIndicator, 3, 0, 1, coreLowest);
   
   double current = price.At(symbol, 0).close;
   double gap = highest[0] - lowest[0];

   double tpAdd;
   if(IsBetween(current, coreLowest[0], coreHighest[0]) && positionCore > 0) {
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
   bool sellCondition = current > coreLowest[0];
   bool buyCondition = current < coreHighest[0];
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
      double sl = 9999999;
      double tp = bid - tpAdd;
      tradeRequest tR = {symbol, magicNumber, ORDER_TYPE_SELL, bid, sl, tp};

      lot > 0 ? tR.volume = lot : tVol.CalcurateVolume(tR, logger);
      trade.OpenPosition(tR, logger);
   }
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
