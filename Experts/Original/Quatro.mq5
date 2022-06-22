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
input optimizedTimeframes timeFrame, timeFrameLong;
ENUM_TIMEFRAMES tf = convertENUM_TIMEFRAMES(timeFrame);
ENUM_TIMEFRAMES tfLong = convertENUM_TIMEFRAMES(timeFrameLong);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int digitAdjust = DigitAdjust();
double pips = Pips();
Trade trade(magicNumber);
Price priceLong(tfLong), price(tf);
PositionStore positionStore(magicNumber);
Time time;

Pips trailing;
input int shortPeriod, longPeriodCoef, stopPeriod;
input double tpBuyPips, tpSellPips;
input int atrPeriod, atrPipsMin;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CiATR audUsd;
int OnInit() {
   EventSetTimer(eventTimer);
   int atrIndex = 1;

   audUsd.Create("AUDUSD", tf, atrPeriod);
   audUsd.BufferResize(atrIndex);

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

   if(!CheckNewBarOpen(tf, _Symbol)) {
      return;
   }

   if(!CheckMarketOpen() || !CheckEquityThereShold(equityThereShold)) {
      return;
   }

   if(SymbolInfoInteger(Symbol(), SYMBOL_SPREAD) > spreadLimit) {
      return;
   }

   audUsd.Refresh();
   if(audUsd.Main(0) < atrPipsMin * pips) return;


   string audStr = AUDStrength();
   string usdStr = USDStrength();

   bool buyCondition = audStr == STRONG || usdStr == WEAK;
   bool sellCondition = audStr == WEAK || usdStr == STRONG;

   tradeRequest tR;

   Volume tVol(riskPercent, _Symbol);
   if(buyCondition) {
      double ask = Ask(_Symbol);
      double sl = price.Lowest(0, stopPeriod, _Symbol);
      double tp = ask + tpBuyPips * pips;
      tradeRequest tR = {_Symbol, magicNumber, tf, ORDER_TYPE_BUY, ask, sl, tp};

      if(positionStore.buyTickes.Total() < positionTotal && tVol.CalcurateVolume(tR)) {
         trade.OpenPosition(tR);
      }
   } else if(sellCondition) {
      double bid = Bid(_Symbol);
      double sl = price.Highest(0, stopPeriod, _Symbol);
      double tp = bid - tpSellPips * pips;
      tradeRequest tR = {_Symbol, magicNumber, tf, ORDER_TYPE_SELL, bid, sl, tp};

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
string USDStrength() {
   string USDJPY = Trend("USDJPY");
   string EURUSD = Trend("EURUSD");
   string GBPUSD = Trend("GBPUSD");
   string AUDUSD = Trend("AUDUSD");

   if( USDJPY == BULL && EURUSD == BEAR && GBPUSD == BEAR && AUDUSD == BEAR) {
      return STRONG;
   }
   if( USDJPY == BULL && EURUSD == BEAR && GBPUSD == BEAR && AUDUSD == BEAR) {
      return WEAK;
   }
   return "";
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string AUDStrength() {
   string AUDJPY =   Trend("AUDJPY");
   string AUDUSD = Trend("AUDUSD");
   string EURAUD = Trend("EURAUD");
   string GBPAUD = Trend("GBPAUD");

   if( AUDJPY == BULL && AUDUSD == BULL && EURAUD == BEAR && GBPAUD == BEAR) {
      return STRONG;
   }
   if( AUDJPY == BEAR && AUDUSD == BEAR && EURAUD == BULL && GBPAUD == BULL) {
      return WEAK;
   }
   return "";
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string JPYStrength(string USDJPY, string EURJPY) {
   if(  USDJPY == BULL && EURJPY == BULL) return WEAK;
   if( USDJPY == BEAR && EURJPY == BEAR) return STRONG;

   return "";
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string EURStrength(string EURUSD, string EURJPY) {
   if( EURUSD == BULL && EURJPY == BULL) return STRONG;
   if(  EURUSD == BEAR && EURJPY == BEAR) return WEAK;
   return "";
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string Trend(string symbol) {
   MqlRates pr1 = price.At(1, symbol);
   MqlRates pr2 = price.At(2, symbol);

   MqlRates prLong1 = priceLong.At(1, symbol);
   MqlRates prLong2 = priceLong.At(2, symbol);

   if(pr2.low < pr1.low && pr2.high < pr1.high) {
  
   }
   if(pr2.low > pr1.low && pr2.high > pr1.high) {
 
   }
   return "";

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   double RefreshATR(CiATR & usdJpyATR, CiATR & eurJpyATR, CiATR & eurUsdATR, string symbol) {
      if(symbol == "USDJPY") {
         usdJpyATR.Refresh();
         return usdJpyATR.Main(0);
      } else if(symbol == "EURUSD") {
         eurUsdATR.Refresh();
         return eurUsdATR.Main(0);
      } else if(symbol == "EURJPY") {
         eurJpyATR.Refresh();
         return eurJpyATR.Main(0);
      }
      return 0;
   }

   enum strength {
      STRONG,
      WEAK
   };

   enum trend {
      BULL,
      BEAR
   };
//+------------------------------------------------------------------+

   
