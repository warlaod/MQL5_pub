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
input int atrPeriod, atrMinVal;
input int slPips;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CiATR ATR;
int OnInit() {
   EventSetTimer(eventTimer);
   ADX.Create(_Symbol, tf, ADXPeriod);
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

   ADX.Refresh();
   double atr = ATR.Main(0);
   if(ATR.Main(0) < atrMinVal * _Point * digitAdjust) return;

   string audStrength = AUDStrength(tf, 1);
   if(audStrength == "") return;

   bool buyCondition = audStrength == "string";
   bool sellCondition = audStrength == "weak";

   tradeRequest tR;

   if(buyCondition) {
      double ask = Ask();
      tradeRequest tR = {magicNumber, tf, ORDER_TYPE_BUY, ask, ask - slPips * pips, ask + 50 * pips};

      if(positionStore.buyTickes.Total() < positionTotal && tVol.CalcurateVolume(tR)) {
         trade.OpenPosition(tR);
      }
   } else if(sellCondition) {
      double bid = Bid();
      tradeRequest tR = {magicNumber, tf, ORDER_TYPE_SELL, bid, bid + slPips * pips, bid - 50 * pips};

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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string AUDStrength(ENUM_TIMEFRAMES tf, int index) {
   string AUDJPY = Trend("AUDJPY", tf, index);
   string AUDUSD = Trend("AUDUSD", tf, index);
   string EURAUD = Trend("EURAUD", tf, index);
   string GBPAUD = Trend("GBPAUD", tf, index);

   if( AUDJPY == "bull" && AUDUSD == "bull" && EURAUD == "bear" && GBPAUD == "bear") return "strong";
   if(  AUDJPY == "bear" && AUDUSD == "bear" && EURAUD == "bull" && GBPAUD == "bull") return "weak";
   return "";
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string Trend(string symbol, ENUM_TIMEFRAMES tf, int index) {
   double price[];
   ArraySetAsSeries(price, true);

   CopyLow(symbol, tf, index, index + 1, price);
   if(price[1] < price[0]) {
      return "bull";
   }
   CopyHigh(symbol, tf, index, index + 1, price);
   if(price[1] > price[0]) {
      return "bear";
   }
   return "";
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
