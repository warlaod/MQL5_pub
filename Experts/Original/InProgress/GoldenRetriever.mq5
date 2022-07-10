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
#include <MyPkg\OrderHistory.mqh>
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
input optimizedTimeframes maTimeFrame, stoTimeFrame,forceTimeframe;
ENUM_TIMEFRAMES tf = convertENUM_TIMEFRAMES(maTimeFrame);
ENUM_TIMEFRAMES forceTf = convertENUM_TIMEFRAMES(forceTimeframe);
ENUM_TIMEFRAMES stoTf = convertENUM_TIMEFRAMES(stoTimeFrame);

input ENUM_MA_METHOD maMA, stoMA, forceMA;
input ENUM_APPLIED_PRICE appliedPrice;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double pips = Pips();
string symbol = _Symbol;
Trade trade(magicNumber);
Price price(tf);
Volume tVol(riskPercent, _Symbol);
PositionStore positionStore(magicNumber);
Time time;
OrderHistory orderHistory(magicNumber);

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CiMA maLong, maShort;
CiForce force;
CiStochastic sto;
Appointed trailing;
input int maPeriod;
input int stoSignalLimit;
input int k, d, slowD;
input int slPips, stopPeriod;
input int forcePeriod;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   EventSetTimer(eventTimer);

   maLong.Create(symbol, tf,  maPeriod, 0, maMA, appliedPrice);
   maLong.BufferResize(1);

   sto.Create(symbol, stoTf, k, 3, 3, stoMA, STO_LOWHIGH);
   sto.BufferResize(2);
   force.Create(symbol, forceTf, forcePeriod, forceMA, VOLUME_TICK);
   force.BufferResize(2);



   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   time.Refresh();
   positionStore.Refresh();

   maLong.Refresh();
   double maLong0 = maLong.Main(0);
   double longSL = price.Lowest(symbol, 0, stopPeriod) - slPips * pips;
   double shortSL = price.Highest(symbol, 0, stopPeriod) + slPips * pips;

   trailing.TrailLongs(symbol, positionStore.buyTickets, longSL, maLong0);
   trailing.TrailShorts(symbol, positionStore.sellTickets, shortSL, maLong0);

   // don't trade before 2 hours from market close
   if(time.CheckTimeOver(FRIDAY, whenToCloseOnFriday - 2)) {
      if(time.CheckTimeOver(FRIDAY, whenToCloseOnFriday - 1)) {
         trade.ClosePositions(positionStore.buyTickets);
         trade.ClosePositions(positionStore.sellTickets);
      }
      return;
   }

   if(!CheckMarketOpen() || !CheckEquityThereShold(equityThereShold) || orderHistory.wasOrderInTheSameBar(symbol, tf)) {
      return;
   }

   if(SymbolInfoInteger(Symbol(), SYMBOL_SPREAD) > spreadLimit) {
      return;
   }

   force.Refresh();
   sto.Refresh();

   bool buyCondition = force.Main(0) > 0
                       && sto.Signal(1) < stoSignalLimit
                       && sto.Signal(1) > sto.Main(1) && sto.Signal(0) < sto.Main(0);

   bool sellCondition = force.Main(0) < 0
                        && sto.Signal(1) > 100 - stoSignalLimit
                        && sto.Signal(1) < sto.Main(1) && sto.Signal(0) > sto.Main(0);


   tradeRequest tR;


   if(buyCondition) {
      double ask = Ask(symbol);
      double sl = longSL;
      double tp = maLong0;
      tradeRequest tR = {symbol, magicNumber, tf, ORDER_TYPE_BUY, ask, sl, tp};

      if(positionStore.buyTickets.Total() < positionTotal && tVol.CalcurateVolume(tR)) {
         trade.OpenPosition(tR);
      }
   } else if(sellCondition) {
      double bid = Bid(symbol);
      double sl = shortSL;
      double tp = maLong0;
      tradeRequest tR = {symbol, magicNumber, tf, ORDER_TYPE_SELL, bid, sl, tp};

      if(positionStore.sellTickets.Total() < positionTotal && tVol.CalcurateVolume(tR)) {
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
