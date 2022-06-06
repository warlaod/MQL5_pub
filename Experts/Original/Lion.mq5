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
#include <MyPkg\Trade\Volume.mqh>
#include <MyPkg\Price.mqh>
#include <MyPkg\Position\PositionStore.mqh>
#include <MyPkg\Time.mqh>
#include <MyPkg\Trailing\Appointed.mqh>
#include <MyPkg\Trailing\Pips.mqh>
#include <Indicators\TimeSeries.mqh>
#include <Indicators\Oscilators.mqh>
#include <Indicators\Trend.mqh>
#include <Indicators\BillWilliams.mqh>
#include <Indicators\Volumes.mqh>

int eventTimer = 60; // The frequency of OnTimer
input ulong magicNumber = 21984;
input int equityThereShold = 1500;
input int riskPercent = 2;
input int positionTotal = 1;
input int whenToCloseOnFriday = 23;
input int spreadLimit = 999;
input optimizedTimeframes timeFrame;
ENUM_TIMEFRAMES tf = convertENUM_TIMEFRAMES(timeFrame);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int digitAdjust = DigitAdjust();
double pips = Pips();
Trade trade(magicNumber);
Price price(tf);
Volume tVol(riskPercent);
PositionStore positionStore(magicNumber);
Time time;

Pips trailing;
input int stopPeriod;
input double tpPips;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CiATR ATR;
int OnInit() {
   EventSetTimer(eventTimer);
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
         trade.ClosePositions(positionStore.buyTickes);
         trade.ClosePositions(positionStore.sellTickes);
      }
      return;
   }

   if(!CheckMarketOpen() || !CheckEquityThereShold(equityThereShold) || !CheckNewBarOpen(tf)) {
      return;
   }

   if(SymbolInfoInteger(Symbol(), SYMBOL_SPREAD) > spreadLimit) {
      return;
   }

   int index = 1;
   string USDJPY = Trend("USDJPY", tf, index);
   string EURJPY = Trend("EURJPY", tf, index);
   string EURUSD = Trend("EURUSD", tf, index);

   string USD = USDStrength(USDJPY, EURUSD);
   string JPY = JPYStrength(USDJPY, EURJPY);
   string EUR = EURStrength(EURUSD, EURJPY);

   bool buyCondition;
   bool sellCondition;
   string symbol;
   
   if(USD == STRONG && JPY == WEAK) {
      symbol = "USDJPY";
      buyCondition = true;
   }else if(USD == WEAK && JPY == STRONG){
      symbol = "USDJPY";
      sellCondition = true;
   }else if(EUR == STRONG && USD == WEAK){
      symbol = "EURUSD";
      buyCondition = true;
   }else if(EUR == WEAK && USD == STRONG){
      symbol = "EURUSD";
      sellCondition = true;
   }else if(EUR == STRONG && JPY == WEAK){
      symbol = "EURJPY";
      buyCondition = true;
   }else if(EUR == WEAK && JPY == STRONG){
      symbol = "EURJPY";
      sellCondition = true;
   }

   tradeRequest tR;

   if(buyCondition) {
      double ask = Ask();
      double sl = price.Lowest(0, stopPeriod);
      double tp = ask + tpPips * pips;
      tradeRequest tR = {symbol,magicNumber, tf, ORDER_TYPE_BUY, ask, sl, tp};

      if(positionStore.buyTickes.Total() < positionTotal && tVol.CalcurateVolume(tR)) {
         trade.OpenPosition(tR);
      }
   } else if(sellCondition) {
      double bid = Bid();
      double sl = price.Highest(0, stopPeriod);
      double tp = bid - tpPips * pips;
      tradeRequest tR = {symbol,magicNumber, tf, ORDER_TYPE_SELL, bid, sl, tp};

      if(positionStore.sellTickes.Total() < positionTotal && tVol.CalcurateVolume(tR)) {
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
//|                                                                  |
//+------------------------------------------------------------------+
string USDStrength(string USDJPY, string EURUSD) {
   if( USDJPY == "bull" && EURUSD == "bear") return STRONG;
   if(  USDJPY == "bear" && EURUSD == "bull") return WEAK;
   return "";
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string JPYStrength(string USDJPY, string EURJPY) {
   if(  USDJPY == "bull" && EURJPY == "bull") return WEAK;
   if( USDJPY == "bear" && EURJPY == "bear") return STRONG;

   return "";
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string EURStrength(string EURUSD, string EURJPY) {
   if( EURUSD == "bull" && EURJPY == "bull") return STRONG;
   if(  EURUSD == "bear" && EURJPY == "bear") return WEAK;
   return "";
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string Trend(string symbol, ENUM_TIMEFRAMES tf, int index) {
   MqlRates price[];
   ArraySetAsSeries(price, true);

   CopyRates(symbol, tf, index, index + 2, price);
   if(price[2].low < price[1].low) {
      return "bull";
   }
   if(price[2].high > price[1].high) {
      return "bear";
   }
   return "";
}

enum strength {
   STRONG,
   WEAK
};
//+------------------------------------------------------------------+
