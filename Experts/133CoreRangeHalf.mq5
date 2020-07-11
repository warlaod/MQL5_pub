//+------------------------------------------------------------------+
//|                                            1009ScalpFractals.mq5 |
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
#include <Original\Ontester.mqh>
#include <Original\caluculate.mqh>
CTrade trade;

MqlDateTime dt;
MqlRates Price[];
input int MIN;
input int positions=2;
input int denom = 30000;
input int spread;
double lot = 0.10;
double  Bid,Ask;
bool tradable = false;
string signal;

int OsmaIndicator;
double Osma[];
input int IchimokuPeriod;
input ENUM_TIMEFRAMES OsmaTimeframe;
input ENUM_APPLIED_PRICE OsmaAppliedPrice;

input int PriceRange;


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   EventSetTimer(3600*24);
   OsmaIndicator = iOsMA(_Symbol,OsmaTimeframe,12,26,9,OsmaAppliedPrice);
   ArraySetAsSeries(Osma,true);
   ArraySetAsSeries(Price,true);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer()
  {

   Bid=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
   Ask=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
   
   CopyBuffer(OsmaIndicator,0,0,1,Osma);
   CopyRates(_Symbol,PERIOD_MN1,0,PriceRange,Price);
   
   double LowestPrice = LowestPrice(_Symbol,PERIOD_MN1,PriceRange);
   double HighestPrice = HighestPrice(_Symbol,PERIOD_MN1,PriceRange);

   if(isTooBigSpread(spread))
     {
      return;
     }


   signal = "";

   if(true)
     {
      signal = "sell";
     }
   else
      if(true)
        {
         signal = "buy";
        }

   if(EachPositionsTotal("buy") < positions && signal=="buy")
     {
      trade.Buy(lot,NULL,Ask,Ask-50*_Point,Ask+50*_Point,NULL);
     }

   if(EachPositionsTotal("sell") < positions && signal=="sell")
     {
      trade.Sell(lot,NULL,Bid,Bid+50*_Point,Bid-50*_Point,NULL);
     }
  }
//+------------------------------------------------------------------+
double OnTester()
  {
   if(!setVariables())
     {
      return -99999999;
     }
   return testingNormal();

  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
