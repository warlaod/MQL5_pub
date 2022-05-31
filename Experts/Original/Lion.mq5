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
#include <MyPkg\Trailing\Indicator.mqh>
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
Trade trade(magicNumber);
Price price(tf);
Volume tVol(riskPercent);
PositionStore positionStore(magicNumber);
Time time;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CiForce USDJPY, EURUSD, GBPUSD, AUDUSD,
        AUDJPY, EURAUD, GBPAUD;
Indicator trailing;

input int tpPips, slPeriod;

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

   USDJPY.Refresh();
   EURUSD.Refresh();
   GBPUSD.Refresh();
   AUDUSD.Refresh();
   AUDJPY.Refresh();
   EURAUD.Refresh();
   GBPAUD.Refresh();

   string audStrength = AUDStrength(tf, 2);
   if(audStrength == "") return;

   string usdStrength = USDStrength(tf, 2);
   if(usdStrength == "") return;

   bool buyCondition = (audStrength == "string" && usdStrength == "weak");
   bool sellCondition = (audStrength == "weak" && usdStrength == "strong");

   tradeRequest tR;

   if(buyCondition) {
      double ask = Ask();
      double tp = ask + tpPips *_Point * digitAdjust;
      double sl = price.Lowest(0,slPeriod);
      if( (tp-ask) / (ask-sl) < 1.0) return;
      tradeRequest tR = {magicNumber, PERIOD_M5, ORDER_TYPE_BUY, ask, sl, tp};

      if(positionStore.buyTickes.Total() < positionTotal && tVol.CalcurateVolume(tR)) {
         trade.OpenPosition(tR);
      }
   } else if(sellCondition) {
      double bid = Bid();
      double tp = bid - tpPips *_Point * digitAdjust;
      double sl = price.Highest(0,slPeriod);
      if( (bid-tp) / (sl-bid) < 1.0) return;
      
      tradeRequest tR = {magicNumber, PERIOD_M5, ORDER_TYPE_SELL, bid, sl, tp};

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
string USDStrength(ENUM_TIMEFRAMES tf, int index) {
   string USDJPY = Trend("USDJPY", tf, index);
   string EURUSD = Trend("EURUSD", tf, index);
   string GBPUSD = Trend("GBPUSD", tf, index);
   string AUDUSD = Trend("AUDUSD", tf, index);

   if( USDJPY == "bull" && EURUSD == "bear" && GBPUSD == "bear" && AUDUSD == "bear") return "strong";
   if(  USDJPY == "bear" && EURUSD == "bull" && GBPUSD == "bull" && AUDUSD == "bull") return "weak";
   return "";
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string Trend(string symbol, ENUM_TIMEFRAMES tf, int index) {
   MqlRates price[];
   ArraySetAsSeries(price, true);
   CopyRates(symbol, tf, index, index + 1, price);

   if(price[index].low < price[index - 1].low) {
      return "bull";
   }
   if(price[index].high > price[index - 1].high) {
      return "bear";
   }
   return "";
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
