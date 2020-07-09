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

int IchimokuIndicator;
double Tenkan[];
input int IchimokuPeriod;


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   EventSetTimer(300);
   IchimokuIndicator = iIchimoku(_Symbol,Timeframe(IchimokuPeriod),9,26,52);

   ArraySetAsSeries(Tenkan,true);
   ArraySetAsSeries(Price,true);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {

   Bid=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
   Ask=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);

   CopyBuffer(IchimokuIndicator,0,0,1, Tenkan);
   CopyRates(_Symbol,Timeframe(IchimokuPeriod),0,1,Price);

   if(tradable == false || isTooBigSpread(spread))
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

   if(EachPositionsTotal("buy") < positions/2 && signal=="buy")
     {
      trade.Buy(lot,NULL,Ask,Ask-50*_Point,Ask+50*_Point,NULL);
     }

   if(EachPositionsTotal("sell") < positions/2 && signal=="sell")
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
void OnTimer()
  {
   //lot = SetLot(denom);
   tradable  = true;
//lot =SetLot(denom);
   if(isNotEnoughMoney())
     {
      tradable = false;
      return;
     }

   TimeToStruct(TimeCurrent(),dt);
   if(dt.day_of_week == FRIDAY)
     {
      if((dt.hour == 22 && dt.min > 0) || dt.hour == 23)
        {
         CloseAllBuyPositions();
         CloseAllSellPositions();
         tradable = false;
         return;
        }
     }

   if(isYearEnd(dt.mon,dt.day))
     {
      tradable = false;
      return;
     }
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
