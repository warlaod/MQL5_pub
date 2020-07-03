//+------------------------------------------------------------------+
//|                                          1017ScalpStochastic.mq5 |
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
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

#include <Trade\Trade.mqh>
#include <Original\prices.mqh>
#include <Original\positions.mqh>
#include <Original\period.mqh>
CTrade trade;
input int span1 = 5;
input int span2 = 0;
input int span3 = 0;
input int span4 = 0;
input int positions = 1;
input int TP = 10;
input int SL = 10;
input int period = 0;
input int indperiod1 = 0;
input int indperiod2 = 0;
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
   ENUM_TIMEFRAMES indperiod2 = Timeframe(indperiod2);
   double Bid=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
   double Ask=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
   string signal = "";
   MqlRates PriceInfo[];
   CopyRates(_Symbol,period,0,2,PriceInfo);
   double LatestPrice = PriceInfo[1].close;
   double lot = 0.10;


   double KArray[];
   double DArray[];
   ArraySetAsSeries(KArray,true);
   ArraySetAsSeries(DArray,true);
   int StochasticDefinition = iStochastic(_Symbol,indperiod1,span1,span2,span3,MODE_EMA,STO_LOWHIGH);
   CopyBuffer(StochasticDefinition,0,0,3,KArray);
   CopyBuffer(StochasticDefinition,1,0,3,DArray);
   double KValue0 = KArray[0];
   double DValue0 = DArray[0];
   double KValue1 = KArray[1];
   double DValue1 = DArray[1];
   
   double MAArray[];
   ArraySetAsSeries(MAArray,true);
   CopyBuffer(iMA(_Symbol,indperiod2,span4,0,MODE_EMA,PRICE_CLOSE),0,0,3,MAArray);
   


   if(KValue0<20 && DValue0<20 && (MAArray[0] < MAArray[1]))
     {
      if(KValue0>DValue0 && KValue1<DValue1)
        {
         signal ="buy";
        }
     }

   if(KValue0>80 && DValue0>80 && (MAArray[0] > MAArray[1]))
     {
      if(KValue0<DValue0 && KValue1>DValue1)
        {
         signal ="sell";
        }
     }









   if((signal =="sell") && (PositionsTotal()< positions))
      trade.Sell(lot,NULL,Bid,Bid+SL*_Point,Bid-TP*_Point,NULL);

   if((signal =="buy") && (PositionsTotal()< positions))
      trade.Buy(lot,NULL,Ask,Ask-SL*_Point,Ask+TP*_Point,NULL);

  }
//+------------------------------------------------------------------+
