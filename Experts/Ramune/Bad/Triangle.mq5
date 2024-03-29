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
#include <Ramune\OptimizedParameter.mqh>
#include <Ramune\Optimization.mqh>
#include <Ramune\Trade\Trade.mqh>
#include <Ramune\Trade\Volume.mqh>
#include <Ramune\Price.mqh>
#include <Ramune\Position\PositionStore.mqh>
#include <Ramune\Time.mqh>
#include <Ramune\Trailing\Appointed.mqh>
#include <Ramune\Trailing\Pips.mqh>
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
PositionStore positionStore(magicNumber);
Time time;

Pips trailing;
input int shortPeriod, longPeriodCoef, stopPeriod;
input double tpBuyPips, tpSellPips;
input int atrPeriod,atrPipsMin;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CiATR usdJpyATR, eurUsdATR, eurJpyATR;
int OnInit() {
   EventSetTimer(eventTimer);
   int atrIndex = 1;

   usdJpyATR.Create("USDJPY", tf, atrPeriod);
   usdJpyATR.BufferResize(atrIndex);

   eurUsdATR.Create("EURUSD", tf, atrPeriod);
   eurUsdATR.BufferResize(atrIndex);

   eurJpyATR.Create("EURJPY", tf, atrPeriod);
   eurJpyATR.BufferResize(atrIndex);

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

   if(!CheckMarketOpen() || !CheckEquityThereShold(equityThereShold)) {
      return;
   }

   if(SymbolInfoInteger(Symbol(), SYMBOL_SPREAD) > spreadLimit) {
      return;
   }

   int index = 1;
   string USDJPY = Trend("USDJPY");
   string EURJPY = Trend("EURJPY");
   string EURUSD = Trend("EURUSD");

   string USD = USDStrength(USDJPY, EURUSD);
   string JPY = JPYStrength(USDJPY, EURJPY);
   string EUR = EURStrength(EURUSD, EURJPY);

   bool buyCondition;
   bool sellCondition;
   string symbol;

   if(USD == STRONG && JPY == WEAK) {
      symbol = "USDJPY";
      buyCondition = true;
   } else if(USD == WEAK && JPY == STRONG) {
      symbol = "USDJPY";
      sellCondition = true;
   } else if(EUR == STRONG && USD == WEAK) {
      symbol = "EURUSD";
      buyCondition = true;
   } else if(EUR == WEAK && USD == STRONG) {
      symbol = "EURUSD";
      sellCondition = true;
   } else if(EUR == STRONG && JPY == WEAK) {
      symbol = "EURJPY";
      buyCondition = true;
   } else if(EUR == WEAK && JPY == STRONG) {
      symbol = "EURJPY";
      sellCondition = true;
   } else {
      return;
   }

   tradeRequest tR;

   Volume tVol(riskPercent, symbol);
   if(!CheckNewBarOpen(tf, symbol)) {
      return;
   }
   
   double atrVal = RefreshATR(usdJpyATR, eurJpyATR, eurUsdATR, symbol);
   if(atrVal < atrPipsMin * pips) return;

   if(buyCondition) {
      double ask = Ask(symbol);
      double sl = price.Lowest(0, stopPeriod, symbol);
      double tp = ask + tpBuyPips * pips;
      tradeRequest tR = {symbol, magicNumber, tf, ORDER_TYPE_BUY, ask, sl, tp};

      if(positionStore.buyTickes.Total() < positionTotal && tVol.CalcurateVolume(tR)) {
         trade.OpenPosition(tR);
      }
   } else if(sellCondition) {
      double bid = Bid(symbol);
      double sl = price.Highest(0, stopPeriod, symbol);
      double tp = bid - tpSellPips * pips;
      tradeRequest tR = {symbol, magicNumber, tf, ORDER_TYPE_SELL, bid, sl, tp};

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
   if( USDJPY == BULL && EURUSD == BEAR) return STRONG;
   if(  USDJPY == BEAR && EURUSD == BULL) return WEAK;
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
   MqlRates pr1 = price.At(1,symbol);
   MqlRates pr2 = price.At(2,symbol);
   
   if(pr2.low < pr1.low && pr2.high < pr1.high){
      return BULL;
   }
   if(pr2.low > pr1.low && pr2.high > pr1.high){
      return BEAR;
   }
   return "";
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double RefreshATR(CiATR &usdJpyATR, CiATR &eurJpyATR, CiATR &eurUsdATR, string symbol) {
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
