//+------------------------------------------------------------------+
//|                                                  1016ScalpMA.mq5 |
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
#include <Original\account.mqh>
CTrade trade;
input int span1 = 5;
input int span2 = 0;
input int span3 = 0;
input int span4 = 0;
input int indperiod1 = 0;
input int indperiod2 = 0;
input int TP = 30;
input int SL = 30;
input int indparam1 = 0;
input int indparam2 = 0;
input int SLSecondRange = 2940;
input int SLUpperLimit = 3;
input int SLTradeRange = 4;
input int positions = 1;
string signal = "";
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(isNotEnoughMoney()){
      return;
   }
   int untradableJP[] = {4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19};
   if(isTooBigSpread(4))
     {
      return;
     }
   MqlDateTime dt;
   TimeToStruct(TimeCurrent()+6*3600,dt);


   
   ENUM_TIMEFRAMES indperiod1 = Timeframe(indperiod1);
   ENUM_TIMEFRAMES indperiod2 = Timeframe(indperiod2);
   double Bid=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
   double Ask=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
   
   MqlRates PriceInfo[];
   ArraySetAsSeries(PriceInfo,true);
   CopyRates(_Symbol,_Period,0,2,PriceInfo);
   double LatestPrice = PriceInfo[1].close;
   double lot = 0.10;

   double MAS[],MAM[],MAL[];
   ArraySetAsSeries(MAS,true);
   ArraySetAsSeries(MAM,true);
   ArraySetAsSeries(MAL,true);
   CopyBuffer(iMA(_Symbol,indperiod1,span1,0,MODE_EMA,PRICE_CLOSE),0,0,3,MAS);
   CopyBuffer(iMA(_Symbol,indperiod1,span2,0,MODE_EMA,PRICE_CLOSE),0,0,3,MAM);
   CopyBuffer(iMA(_Symbol,indperiod1,span3,0,MODE_EMA,PRICE_CLOSE),0,0,3,MAL);




   if( MAL[0] < MAS[0]  && (MathAbs(MAL[0] - MAS[0])-MathAbs(MAL[1] - MAS[1]) > 0))
     {
      signal="buy";
     }

   if( MAL[0] > MAS[0] && (MathAbs(MAL[0] - MAS[0])-MathAbs(MAL[1] - MAS[1]) > 0) )
     {
      signal="sell";
     }

   if((signal =="sell") && (PositionsTotal()< positions))
     {
      double LowestPrice = LowestPrice(_Symbol,indperiod2,indparam1);
      trade.Sell(0.10,NULL,Bid,Bid+SL*_Point,LowestPrice-TP*_Point,NULL);
     }

   if((signal =="buy") && (PositionsTotal()< positions))
     {
      double HighestPrice = HighestPrice(_Symbol,indperiod2,indparam1);
      trade.Buy(0.10,NULL,Ask,Ask-SL*_Point,HighestPrice+TP*_Point,NULL);
     }
     
    Comment(
      "PriceInfoLow0:",PriceInfo[0].low,"\n",
      "PriceInfoLow1:",PriceInfo[1].low,"\n",
      "MAS[0]:", MAS[0],"\n",
      "Bool:",(MAS[0] > PriceInfo[0].low),"\n"
      );
  }
//+------------------------------------------------------------------+
