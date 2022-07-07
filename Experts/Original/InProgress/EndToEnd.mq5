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
#include <MyPkg\Position\Position.mqh>
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
input optimizedTimeframes timeFrame;
ENUM_TIMEFRAMES tf = convertENUM_TIMEFRAMES(timeFrame);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double pips = Pips();
string symbol = _Symbol;
Trade trade(magicNumber);
Price price(PERIOD_MN1);
Volume tVol(riskPercent, _Symbol);
PositionStore positionStore(magicNumber);
Position position;
Time time;
OrderHistory orderHistory(magicNumber);

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CiATR atr;
input int atrPeriod,pricePeriod,slPips;
input double middleLimit,topLimit;
input double tpCoef;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   EventSetTimer(eventTimer);
   atr.Create(symbol,tf,atrPeriod);

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   time.Refresh();
   positionStore.Refresh();

   if(!CheckMarketOpen() || !CheckEquityThereShold(equityThereShold) || orderHistory.wasOrderInTheSameBar(symbol, tf)) {
      return;
   }

   if(SymbolInfoInteger(symbol, SYMBOL_SPREAD) > spreadLimit) {
      return;
   }

   double top = price.Highest(symbol,0,pricePeriod);
   double bottom = price.Lowest(symbol,0,pricePeriod);
   double current = price.At(symbol,0).close;
   double perB = (current - bottom) / (top - bottom);

   bool sellCondition = perB > 0.5+middleLimit
   && perB < 1 - topLimit;

   bool buyCondition = perB < 0.5 - middleLimit
   && perB > topLimit;
   
   double range = atr.Main(0) * tpCoef;
   if(buyCondition) {
      double ask = Ask(symbol);
      if(position.IsAnyPositionInRange(positionStore.buyTickets,ask,range)){
      return;
      }
      double sl = bottom - slPips*pips;
      double tp = ask + range;
      tradeRequest tR = {symbol, magicNumber, tf, ORDER_TYPE_BUY, ask, sl, tp};

      if(positionStore.buyTickets.Total() < positionTotal && tVol.CalcurateVolume(tR)) {
         trade.OpenPosition(tR);
      }
   } else if(sellCondition) {
      double bid = Bid(symbol);
      if(position.IsAnyPositionInRange(positionStore.sellTickets,bid,range)){
      return;
      }
      double sl = top + slPips*pips;
      double tp = bid - range;
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
