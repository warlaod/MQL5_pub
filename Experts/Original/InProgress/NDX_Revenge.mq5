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
Price price(tf);
Volume tVol(riskPercent, _Symbol);
PositionStore positionStore(magicNumber);
Time time;
OrderHistory orderHistory(magicNumber);

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CiMA maLong, maShort;
input int maPeriod, maLongPeriodCoef, slPeriod;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   EventSetTimer(eventTimer);

   maLong.Create(symbol, tf,  maPeriod * maLongPeriodCoef, 0, MODE_SMA, PRICE_CLOSE);
   maLong.BufferResize(3);

   maShort.Create(symbol, tf,  maPeriod, 0, MODE_SMA, PRICE_CLOSE);
   maShort.BufferResize(3);

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   time.Refresh();
   positionStore.Refresh();
   psTrailing.Refresh(positionStore.sellTickets,positionStore.buyTickets);

   // If current position has some profit, add list for trailing
   for(int i = positionStore.buyTickets.Total() - 1; i >= 0; i--) {
      ulong ticket = positionStore.buyTickets.At(i);
      double profit = position.ProfitInPips(ticket);
      if(profit > trailPips){
         psTrailing.AddBuyTicket(ticket);
      }
   }
   for(int i = positionStore.sellTickets.Total() - 1; i >= 0; i--) {
      ulong ticket = positionStore.sellTickets.At(i);
      double profit = position.ProfitInPips(ticket);
      if(profit > trailPips){
         psTrailing.AddSellTicket(ticket);
      }
   }
   
   // trailing
   trailing.TrailLongs(_Symbol, psTrailing.buyTickets,trailPips);
   trailing.TrailShorts(_Symbol, psTrailing.sellTickets,trailPips);
   
   // don't trade before 2 hours from market close
   if(time.CheckTimeOver(FRIDAY, whenToCloseOnFriday - 2)) {
      if(time.CheckTimeOver(FRIDAY, whenToCloseOnFriday - 1)) {
         trade.ClosePositions(positionStore.buyTickets);
         trade.ClosePositions(positionStore.sellTickets);
      }
      return;
   }

   if(!CheckMarketOpen() || !CheckEquityThereShold(equityThereShold) || orderHistory.wasOrderInTheSameBar(symbol,tf)) {
      return;
   }

   if(SymbolInfoInteger(Symbol(), SYMBOL_SPREAD) > spreadLimit) {
      return;
   }

   MqlRates price0 = price.At(0, symbol);
   MqlRates price1 = price.At(1, symbol);
   MqlRates price2 = price.At(2, symbol);

   maShort.Refresh();
   maLong.Refresh();

   double maShort0 = maShort.Main(0);
   double maShort1 = maShort.Main(1);
   double maShort2 = maShort.Main(2);
   double maLong0 = maLong.Main(0);
   double maLong1 = maLong.Main(1);
   double maLong2 = maLong.Main(2);

   bool buyCondition = maLong0 > maShort0 && maLong1 > maShort1 && maLong2 > maShort2 &&
                       maShort2 > price2.high && maShort1 > price1.high &&
                       maShort0 < price0.close;
   bool sellCondition = maLong0 < maShort0 && maLong1 < maShort1 && maLong2 < maShort2 &&
                        maShort2 < price2.low && maShort1 < price1.low &&
                        maShort0 > price0.close;

   tradeRequest tR;

   if(buyCondition) {
      double ask = Ask(symbol);
      double sl = price.Lowest(0, slPeriod, symbol);
      double tp = maLong0;
      tradeRequest tR = {symbol, magicNumber, tf, ORDER_TYPE_BUY, ask, sl, tp};

      if(positionStore.buyTickets.Total() < positionTotal && tVol.CalcurateVolume(tR)) {
         trade.OpenPosition(tR);
      }
   } else if(sellCondition) {
      double bid = Bid(symbol);
      double sl = price.Highest(0, slPeriod, symbol);
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
