//+------------------------------------------------------------------+
//|                                               1014ScalpFrAMA.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }

#include <Trade\Trade.mqh>
#include <Original\prices.mqh>
#include <Original\positions.mqh>
#include <Original\period.mqh>
CTrade trade;
input int span1 = 5;
input int span2 = 3;
input int span3 = 3;
input int span4 = 14;
input int positions = 1;
input int TP = 40;
input int SL = 40;
input int period = 0;
input int indperiod1 = 0;
input int SLSecondRange = 2940;
input int SLUpperLimit = 3;
input int SLTradeRange = 4;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   ENUM_TIMEFRAMES period = Timeframe(period);
   ENUM_TIMEFRAMES indperiod1 = Timeframe(indperiod1);
   double Bid=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
   double Ask=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
   string signal = "";
   MqlRates PriceInfo[];
   CopyRates(_Symbol,period,0,2,PriceInfo);
   double LatestPrice = PriceInfo[1].close;
   double lot = 0.10;



   double FrAMAArray[];
   ArraySetAsSeries(FrAMAArray,true);
   CopyBuffer(iFrAMA(_Symbol,indperiod1,span1,0,PRICE_CLOSE),0,0,3,FrAMAArray);
   double FrAMAVal = FrAMAArray[1];


   if(FrAMAVal < PriceInfo[1].high)
     {
      signal = "sell";
     }
   if(LatestPrice > PriceInfo[1].low)
     {
      signal = "buy";
     }

   if((signal =="sell") && (PositionsTotal()< positions))
      trade.Sell(lot,NULL,Bid,Bid+SL*_Point,Bid-TP*_Point,NULL);

   if((signal =="buy") && (PositionsTotal()< positions))
      trade.Buy(lot,NULL,Ask,Ask-SL*_Point,Ask+TP*_Point,NULL);

  }
//+------------------------------------------------------------------+
