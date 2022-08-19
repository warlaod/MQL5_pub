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
#include <MyPkg\Trade\VolumeByMargin.mqh>
#include <MyPkg\Price.mqh>
#include <MyPkg\Position\Position.mqh>
#include <MyPkg\Position\PositionStore.mqh>
#include <MyPkg\Time.mqh>
#include <MyPkg\Trailing\Appointed.mqh>
#include <MyPkg\Trailing\PositionStoreForTrailing.mqh>
#include <MyPkg\OrderHistory.mqh>
#include <Indicators\TimeSeries.mqh>
#include <Indicators\Oscilators.mqh>
#include <Indicators\Trend.mqh>
#include <Indicators\BillWilliams.mqh>
#include <Indicators\Volumes.mqh>

int eventTimer = 60; // The frequency of OnTimer
input ulong magicNumber = 21984;
input int equityThereShold = 1500;
input double riskPercent = 5;
input int positionTotal = 1;
input int whenToCloseOnFriday = 23;
input int spreadLimit = 999;
input optimizedTimeframes timeFrame, trailTimeframe, atrTimeframe;
ENUM_TIMEFRAMES tf = convertENUM_TIMEFRAMES(timeFrame);
ENUM_TIMEFRAMES trailTf = convertENUM_TIMEFRAMES(trailTimeframe);
ENUM_TIMEFRAMES atrTf = convertENUM_TIMEFRAMES(atrTimeframe);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string symbol = _Symbol;
double pips = Pips(symbol);
Trade trade(magicNumber);
Price price(tf);
Price trailPrice(trailTf);
VolumeByMargin tVol(riskPercent, symbol);
PositionStore positionStore(magicNumber, symbol);
Position position(symbol);
Time time;
OrderHistory orderHistory(magicNumber);

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Appointed trailing(symbol);
PositionStoreForTrailing psTrailing;
CiADX adx;
input int slPeriod;
input int trailPeriod;
input int adxPlusLimit, adxMinusLimit;
input int pricePeriod;
input double rangeCoef,tpCoef;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   EventSetTimer(eventTimer);

   adx.Create(symbol, atrTf, 18);
   adx.BufferResize(3);

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

   if(!CheckMarketOpen() || !CheckEquityThereShold(equityThereShold) || orderHistory.wasOrderInTheSameBar(symbol, PERIOD_M2)) {
      return;
   }

   if(Spread(symbol) > spreadLimit * pips) {
      return;
   }

   adx.Refresh();
   
   bool buyCondition = adx.Plus(0) > 20 &&
                       adx.Main(0) > adxPlusLimit &&
                       adx.Main(1) > adx.Main(2);
   bool sellCondition = adx.Minus(0) > 20 &&
                        adx.Main(0) > adxMinusLimit &&
                        adx.Main(1) > adx.Main(2);

   tradeRequest tR;
   
   double gap = price.Highest(symbol, 0, pricePeriod) - price.Lowest(symbol, 0, pricePeriod);

   double range = gap * rangeCoef;

   if(buyCondition && !position.IsAnyPositionInRange(symbol, positionStore.buyTickets, range)) {
      double ask = Ask(symbol);
      double sl = 0;
      double tp = 999999;
      tradeRequest tR = {symbol, magicNumber, ORDER_TYPE_BUY, ask, sl, tp};

      tVol.CalcurateVolume(tR);
      
      double maxVol = SymbolInfoDouble(tR.symbol, SYMBOL_VOLUME_MAX);
      while(tR.volume > maxVol) {
         tradeRequest maxTr = tR;
         maxTr.volume = maxVol;
         trade.OpenPosition(maxTr);
         tR.volume -= maxVol;
      }
      trade.OpenPosition(tR);

   }

   if(sellCondition && !position.IsAnyPositionInRange(symbol, positionStore.sellTickets, range)) {
      double bid = Bid(symbol);
      double sl = trailPrice.Highest(0, slPeriod, symbol);
      double tp = 0;
      tradeRequest tR = {symbol, magicNumber, ORDER_TYPE_SELL, bid, sl, tp};

      tR.volume = SellLot();
      
      double maxVol = SymbolInfoDouble(tR.symbol, SYMBOL_VOLUME_MAX);
      while(tR.volume > maxVol) {
         tradeRequest maxTr = tR;
         maxTr.volume = maxVol;
         trade.OpenPosition(maxTr);
         tR.volume -= maxVol;
      }
      trade.OpenPosition(tR);

   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double OnTester() {
   Optimization optimization;

   if(!optimization.CheckResultValid()) return 0;
   
   double profitFactor = 1 / optimization.equityDdrelPercent;
   double base = optimization.profit;
   double result =  base * profitFactor;
   if(optimization.profit < 0) {
      result = base / profitFactor;
   }

   return result;
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double SellLot() {
   double lot = 0;
   for(int i = 0; i < positionStore.buyTickets.Total(); i++) {
      position.SelectByTicket(positionStore.buyTickets.At(i));
      lot += position.Volume();
   }
   for(int i = 0; i < positionStore.sellTickets.Total(); i++) {
      position.SelectByTicket(positionStore.sellTickets.At(i));
      lot -= position.Volume();
   }
   return lot;
}
//+------------------------------------------------------------------+
