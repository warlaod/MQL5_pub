//+------------------------------------------------------------------+
//|                                                    1003iosma.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
#include <Original\prices.mqh>
#include <Original\positions.mqh>
#include <Original\period.mqh>
#include <Original\account.mqh>
CTrade trade;

input int indperiod1 = 12;
input int indperiod2 = 12;
input int indparam1 = 14;
input int span1 = 6;
input double deviation = 1;
input int positions = 1;
input int pricetype = 1;
input double TPbuy = 0.9985;
input double SLbuy = 0.9940;
input double TPsell = 0.9956;
input double SLsell = 1.0096;
double lot = 0.10;
int Indicator;
double  Bid,Ask;
double high[],low[];
double myRSIArray[];
int myRSIDefinition;
string signal;
ENUM_TIMEFRAMES Indperiod1;
ENUM_TIMEFRAMES Indperiod2;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   Indperiod1 = Timeframe(indperiod1);
   Indperiod2 = Timeframe(indperiod2);
   Indicator =  iBands(_Symbol,Indperiod1,span1,0,deviation,pricetype);

   ArraySetAsSeries(myRSIArray,true);
   myRSIDefinition =iRSI(_Symbol,Indperiod2,indparam1,PRICE_CLOSE);

   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(isNotEnoughMoney())
     {
      return;
     }
   if(isTooBigSpread(4))
     {
      return;
     }

   Bid=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
   Ask=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);

   CopyBuffer(Indicator, 0,0,2, high);
   CopyBuffer(Indicator, 1,0,2, low);

   if(high[0] == EMPTY_VALUE || low[0] == EMPTY_VALUE)
     {
      return;
     }


   CopyBuffer(myRSIDefinition,0,0,1,myRSIArray);
   double myRSIValue = NormalizeDouble(myRSIArray[0],2);

   if(myRSIValue < 30)
     {
      signal="buy";

     }

   if(myRSIValue > 70)
     {
      signal="sell";
     }

  MathSrand(GetTickCount());
   if(PositionsTotal()< positions)
     {
      if(MathRand()%2 == 1)
        {
         if((high[0]*TPbuy - Ask) > 20*_Point && (Ask - low[0]*SLbuy) > 9*_Point)
           {
            trade.Buy(lot,NULL,Ask,low[0]*SLbuy,high[0]*TPbuy,NULL);
           }
        }
      else
         if((Bid - low[0]*TPsell) > 20*_Point  && (high[0]*SLsell- Bid) > 9*_Point)
           {
            trade.Sell(lot,NULL,Bid,high[0]*SLsell,low[0]*TPsell,NULL);
           }
     }
  }
//+------------------------------------------------------------------+
