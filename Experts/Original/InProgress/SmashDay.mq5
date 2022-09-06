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
#include <MyPkg\Trade\VolumeByRisk.mqh>
#include <MyPkg\Price.mqh>
#include <MyPkg\Position\Position.mqh>
#include <MyPkg\Position\PositionStore.mqh>
#include <MyPkg\Trailing\PositionStoreForTrailing.mqh>
#include <MyPkg\Trailing\Appointed.mqh>
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
input optimizedTimeframes timeFrame, indTimeframe,trailTimeframe;
ENUM_TIMEFRAMES tf = convertENUM_TIMEFRAMES(timeFrame);
ENUM_TIMEFRAMES indTf = convertENUM_TIMEFRAMES(indTimeframe);
ENUM_TIMEFRAMES trailTf = convertENUM_TIMEFRAMES(trailTimeframe);

input ENUM_MA_METHOD maMethod;
input ENUM_APPLIED_PRICE appliedPrice;
input int maPeriod,trailPeriod;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

string symbol = _Symbol;
double pips = Pips(symbol);
Trade trade(magicNumber);
Price price(tf);
Price trailPrice(trailTf);
VolumeByRisk tVol(riskPercent,symbol);
PositionStore positionStore(magicNumber,symbol);
Position position(symbol);
Time time;
OrderHistory orderHistory(magicNumber);

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CiMA ma;
Appointed trailing(symbol);
PositionStoreForTrailing psTrailing;
int OnInit() {
   EventSetTimer(eventTimer);

   ma.Create(_Symbol, indTf, maPeriod, 0, maMethod, appliedPrice);
   ma.BufferResize(1);

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   time.Refresh();
   positionStore.Refresh();
   psTrailing.Refresh(positionStore.sellTickets, positionStore.buyTickets);
   
   double nextSellStop = trailPrice.Highest(symbol, 1, trailPeriod);
   for(int i = positionStore.sellTickets.Total() - 1; i >= 0; i--) {
      ulong ticket = positionStore.sellTickets.At(i);
      double nextProfit = position.ProfitOnNextStopLoss(ticket,nextSellStop);
      if(nextProfit > 0) {
         psTrailing.AddSellTicket(ticket);
      }
   }
   
   double nextBuyStop = trailPrice.Lowest(symbol, 1, trailPeriod);
   for(int i = positionStore.buyTickets.Total() - 1; i >= 0; i--) {
      ulong ticket = positionStore.buyTickets.At(i);
      double nextProfit = position.ProfitOnNextStopLoss(ticket,nextBuyStop);
      if(nextProfit > 0) {
         psTrailing.AddSellTicket(ticket);
      }
   }

// trailing
   trailing.TrailShorts(symbol, psTrailing.sellTickets, nextSellStop, Bid(symbol) - 4000);
   // don't trade before 2 hours from market close
   if(time.CheckTimeOver(FRIDAY, whenToCloseOnFriday - 2)) {
      if(time.CheckTimeOver(FRIDAY, whenToCloseOnFriday - 1)) {
         trade.ClosePositions(positionStore.buyTickets);
         trade.ClosePositions(positionStore.sellTickets);
      }
      return;
   }

   if(!CheckMarketOpen() || !CheckEquityThereShold(equityThereShold) || orderHistory.wasOrderInTheSameBar(_Symbol,tf)) {
      return;
   }

   if(SymbolInfoInteger(Symbol(),SYMBOL_SPREAD) > spreadLimit){
      return;
   }
   
   ma.Refresh();
   double lastTrend = ma.Main(1) - ma.Main(2);
   double trend = ma.Main(0) - ma.Main(1);

   bool buyCondition = lastTrend < 0 && trend > 0;
   bool sellCondition = lastTrend < 0 && trend > 0;

   tradeRequest tR;

   if(buyCondition) {
      double ask = Ask(symbol);
      double sl =
      double tp = 
      tradeRequest tR = {symbol,magicNumber, ORDER_TYPE_BUY, ask, ask - sl * pips, ask + tp * pips};
      
      myTrade.BuyStop(myPrice.At(1).high, myPrice.At(2).low, myPrice.At(1).high + TPCoef * pipsToPrice);

      if(positionStore.buyTickets.Total() < positionTotal && tVol.CalcurateVolume(tR)) {
         trade.OpenPosition(tR);
      }
   } else if(sellCondition) {
      double bid = Bid(symbol);
      tradeRequest tR = {symbol, magicNumber, ORDER_TYPE_SELL, bid, bid + sl*pips, bid - tp * pips};

      if(positionStore.sellTickets.Total() < positionTotal && tVol.CalcurateVolume(tR)) {
         trade.OpenPosition(tR);
      }
   }
}

double OnTester(){
   Optimization optimization;
   return optimization.Custom2();
}
