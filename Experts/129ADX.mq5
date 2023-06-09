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
input int positions,denom;
double lot = 0.10;
double  Bid,Ask;
input int spread;
string signal;
bool tradable = true;

int ADXIndicator;
double Main[],Plus[],Minus[];
input int ADXPeriod;

input int TP,SL;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   EventSetTimer(300);
   ArraySetAsSeries(Main,true);
   ArraySetAsSeries(Plus,true);
   ArraySetAsSeries(Minus,true);
   ADXIndicator =  iADX(_Symbol,Timeframe(ADXPeriod),14);

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {

   if(tradable == false || isTooBigSpread(spread))
     {
      return;
     }
   Bid=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
   Ask=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);


   CopyBuffer(ADXIndicator, 0,0,2, Main);
   CopyBuffer(ADXIndicator, 1,0,2, Plus);
   CopyBuffer(ADXIndicator, 2,0,2, Minus);
   signal = "";

   if(Plus[0] > Main[0] && Main[0] > Minus[0] && Main[1] < Minus[1])
     {
      signal = "buy";
     }
   else
      if(Minus[0] > Main[0] && Main[0] > Plus[0] && Main[1] < Plus[1])
        {
         signal = "sell";
        }


   if(EachPositionsTotal("buy") < positions/2 && signal =="buy")
     {
      trade.Buy(lot,NULL,Ask,Ask-TP*_Point,Ask+SL*_Point,NULL);
     }

   if(EachPositionsTotal("sell") < positions/2 && signal =="sell")
     {
      trade.Sell(lot,NULL,Bid,Bid+TP*_Point,Bid-SL*_Point,NULL);
     }
  }
//+------------------------------------------------------------------+
double OnTester()
  {
   if(!setVariables())
     {
      return -99999999;
     }
   return testingScalp();

  }
//+------------------------------------------------------------------+
void OnTimer()
  {
   tradable  = true;
//lot =SetLot(denom);
   if(isNotEnoughMoney())
     {
      tradable = false;
      return;
     }

   TimeToStruct(TimeCurrent()-3600*3,dt);
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

/*
     int current = TimeCurrent(); GMT+3 (サーバー時間)
   int gmt = TimeGMT(); GMT+0;
   int gmtoffset = TimeGMTOffset(); local - GMT    ...9hours
   int local = TimeLocal(); GMT+9

*/
//+------------------------------------------------------------------+
