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

string symbol = _Symbol;
double pips = Pips(symbol);
Trade trade(magicNumber);
Price price(tf);
VolumeByRisk tVol(riskPercent,symbol);
PositionStore positionStore(magicNumber,symbol);
Time time;
OrderHistory orderHistory(magicNumber);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CiAlligator Allig;
CiATR ATR;

input int tp, sl;
input int atrPeriod, atrMinVal;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   EventSetTimer(eventTimer);

   Allig.Create(symbol, tf, 13, 8, 8, 5, 5, 3, MODE_SMMA, PRICE_MEDIAN);
   Allig.BufferResize(13); // How many data should be referenced and updated

   ATR.Create(symbol, tf, atrPeriod);
   ATR.BufferResize(1);
   
   int fractal = iCustom(symbol,tf,"FractalLine");

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

   ATR.Refresh();
   double atr = ATR.Main(0);

   if(ATR.Main(0) < atrMinVal * pips) return;

   Allig.Refresh();
   double jaw = Allig.Jaw(-2);
   double teeth = Allig.Teeth(-2);
   double lips = Allig.Lips(-2);

   bool buyCondition = Allig.Lips(-1) < Allig.Teeth(-1) && Allig.Lips(-2) > Allig.Teeth(-2);
   bool sellCondition = Allig.Lips(-1) > Allig.Teeth(-1) && Allig.Lips(-2) < Allig.Teeth(-2);

   tradeRequest tR;

   if(buyCondition) {
      double ask = Ask(symbol);
      tradeRequest tR = {symbol,magicNumber, ORDER_TYPE_BUY, ask, ask - sl * pips, ask + tp * pips};

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
