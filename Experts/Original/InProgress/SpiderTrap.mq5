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
#include <Indicators\TimeSeries.mqh>
#include <Indicators\Oscilators.mqh>
#include <Indicators\Trend.mqh>
#include <Indicators\BillWilliams.mqh>
#include <Indicators\Volumes.mqh>

int eventTimer = 60; // The frequency of OnTimer
input ulong magicNumber = 21984;
input int equityThereShold = 1500;
input int riskPercent = 5;
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
Volume tVol(riskPercent, _Symbol);
PositionStore positionStore(magicNumber);
Time time;

CiBands Bands;

input int bandsPeriod;
input double minProfitRatio;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   EventSetTimer(eventTimer);

   Bands.Create(_Symbol, tf, bandsPeriod, 0, 2, PRICE_TYPICAL);
   Bands.BufferResize(3); // How many data should be referenced and updated

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   time.Refresh();
   positionStore.Refresh();
   // don't trade before 2 hours from market close
   if(!CheckMarketOpen() || !CheckEquityThereShold(equityThereShold) || !CheckNewBarOpen(tf, _Symbol)) {
      return;
   }

   if(SymbolInfoInteger(Symbol(), SYMBOL_SPREAD) > spreadLimit) {
      return;
   }



   Bands.Refresh();
   double base2 = Bands.Base(2);
   double base1 = Bands.Base(1);
   double upper = Bands.Upper(1);
   double lower = Bands.Lower(1);
   MqlRates pr2 = price.At(2, _Symbol);
   MqlRates pr1 = price.At(1, _Symbol);

   bool buyCondition = pr2.high > base2 && pr1.low < lower;
   bool sellCondition = pr2.low < base2 && pr1.high > upper;

   tradeRequest tR;

   if(buyCondition) {
      double ask = Ask(_Symbol);
      double sl = lower;
      double tp = base1;
      double profitRatio = MathAbs(ask - tp) / MathAbs(ask - sl);
      if(profitRatio < minProfitRatio) return;
      tradeRequest tR = {_Symbol, magicNumber, tf, ORDER_TYPE_BUY, ask, sl, tp};

      if(positionStore.buyTickes.Total() < positionTotal && tVol.CalcurateVolume(tR)) {
         trade.OpenPosition(tR);
      }
   } else if(sellCondition) {
      double bid = Bid(_Symbol);
      double sl = upper;
      double tp = base1;
      double profitRatio = MathAbs(bid - tp) / MathAbs(bid - sl);
      if(profitRatio < minProfitRatio) return;
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
