//+------------------------------------------------------------------+
//|                                                  NewTemplate.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "3.1"
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
#include <Ramune\Trailing\Appointed.mqh>
#include <Ramune\OrderHistory.mqh>
#include <Indicators\TimeSeries.mqh>
#include <Indicators\Oscilators.mqh>
#include <Indicators\Trend.mqh>
#include <Indicators\BillWilliams.mqh>
#resource "\\Indicators\\Ramune\\SimpleCoreRanger_Indicator.ex5" //include the indicator in your file for convenience

int eventTimer = 60; // The frequency of OnTimer
input ulong magicNumber = 21984;
input int stopEquity = 0;
input int stopMarginLevel = 500;
input int stopDrawDownPer = 20;
input int spreadLimit = 20;
input double risk = 2;
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

input uint pricePeriod = 20;
input double coreRange = 0;
input uint positionHalf = 30;
input uint positionCore = 49;
input uint minTP = 55;
input uint maxTP = 271;
input uint sl = 0;
input bool buyOnly = false;

string symbol1 = _Symbol;
int scrIndicator;
Logger logger(symbol1);
int OnInit() {
   EventSetTimer(eventTimer);
   
   if(AccountInfoInteger(ACCOUNT_MARGIN_MODE) == ACCOUNT_MARGIN_MODE_RETAIL_NETTING){
      Alert("This EA does not work on Netting Mode. Use Hedging Mode");
      return(INIT_FAILED);
   }
   
   if(_Period != PERIOD_MN1){
      Alert("please set timeframe Monthly");
      return(INIT_FAILED);
   }
   
   int barMaxCount = iBars(_Symbol, tf);
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
   if(lot <= 0 && risk <= 0) {
      Alert("Please set a value greater than 0 for lot or risk");
      return (INIT_PARAMETERS_INCORRECT);
   }
   if(lot > 0 && risk > 0) {
      Alert("Please set either lot or risk");
      return (INIT_PARAMETERS_INCORRECT);
   }
   
   if(coreRange > 0.5) {
      Alert("Please set a value 0.5 or less for coreRange");
      return (INIT_PARAMETERS_INCORRECT);
   }
   
   scrIndicator = iCustom(symbol1,tf,"::Indicators\\Ramune\\SimpleCoreRanger_Indicator.ex5",coreRange,pricePeriod);
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

   double tpAdd = 0;
   if(IsBetween(current, coreLowest[0], coreHighest[0]) && positionCore > 0) {
      tpAdd = gap * coreRange * 2 / positionCore;
   } 
   if(!IsBetween(current, coreLowest[0], coreHighest[0]) && positionHalf > 0) {
      tpAdd = gap * (1 - coreRange * 2)  / positionHalf;
   }
   
   if(tpAdd == 0) return;

   if(tpAdd < minTP * pips) {
      tpAdd = minTP * pips;
   }
   if(tpAdd > maxTP * pips) {
      tpAdd = maxTP * pips;
   }

   double range = tpAdd;
   bool sellCondition = current > coreLowest[0] && !buyOnly;
   bool buyCondition = current < coreHighest[0];
   VolumeByMargin tVol(risk, symbol);
   
   string comment = "46961:SimpleCoreRanger_EA";
   if(buyCondition) {
      double ask = Ask(symbol);
      if(position.IsAnyPositionInRange(symbol, positionStore.buyTickets, range)) {
         return;
      }
      double stopLoss = sl == 0 ? 0 : ask - sl * pips;
      double tp = ask + tpAdd;
      tradeRequest tR = {symbol, magicNumber, ORDER_TYPE_BUY, ask, stopLoss, tp};

      lot > 0 ? tR.volume = lot : tVol.CalcurateVolume(tR, logger);
      trade.OpenPosition(tR, logger,comment);
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
      trade.OpenPosition(tR, logger,comment);
   }
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
