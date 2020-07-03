//+------------------------------------------------------------------+
//|                                                     templete.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"





#include <Trade\Trade.mqh>
#include <Original\prices.mqh>
#include <Original\positions.mqh>
#include <Original\period.mqh>
#include <Original\account.mqh>
#include <Original\Ontester.mqh>
CTrade trade;


input int positions;
input double TPbuy,SLbuy,TPsell,SLsell;
double lot = 0.10;
MqlDateTime dt;
int Indicator;
input int ENVPeriod;
input int ENVPricetype;
input double ENVDev;
input int ma_method;
double high[],low[];

double Osma[];
int OsmaIndicator;
input int OsmaPeriod;
input int Osmapricetype;
input int ENVparam;
input double OsmaCriPL;
input double OsmaCriMI;

input int MIN;
string signal;
double  Bid,Ask;

input int SL;
input int Trades,Min,Stops;
input int denom;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   ENUM_MA_METHOD ENVmamethod;
   switch(ma_method)
     {
      case 0:
         ENVmamethod = MODE_SMA;
         break;
      case 1:
         ENVmamethod = MODE_EMA;
         break;
      case 2:
         ENVmamethod = MODE_SMMA;
         break;
      case 3:
         ENVmamethod = MODE_LWMA;
         break;
     }

   Indicator =  iEnvelopes(_Symbol,Timeframe(ENVPeriod),ENVparam,0,ENVmamethod,ENVPricetype,ENVDev);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);

   OsmaIndicator = iOsMA(_Symbol,Timeframe(ENVPeriod),12,26,9,Osmapricetype);
   ArraySetAsSeries(Osma,true);

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   TimeToStruct(TimeCurrent(),dt);
   if(dt.day_of_week == FRIDAY)
     {
      if((dt.hour == 22 && dt.min > MIN) || dt.hour == 23)
        {
         CloseAllBuyPositions();
         CloseAllSellPositions();
         return;
        }
     }
   if(isNotEnoughMoney()){
   return;
   }

   if(isTooBigSpread(2))
     {
      return;
     }
   
   lot =SetLot(denom);
 

   

   Bid=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
   Ask=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);

   CopyBuffer(Indicator, 0,0,1, high);
   CopyBuffer(Indicator, 1,0,1, low);

   CopyBuffer(OsmaIndicator,0,0,2,Osma);

   signal = "";

   if(Osma[0] > 0 && Osma[0] > Osma[1] && Osma[0] > OsmaCriPL)
     {
      signal= "buy";
     }
   else
      if(Osma[0] < 0 && Osma[0] < Osma[1] && Osma[0] < -OsmaCriMI)
        {
         signal= "sell";
        }

   if(EachPositionsTotal("buy") < positions/2)
     {
      if(signal =="buy")
        {
         if((high[0]*TPbuy - Ask) > 25*_Point && (Ask - low[0]*SLbuy) > SL*_Point)
           {
            trade.Buy(lot,NULL,Ask,low[0]*SLbuy,high[0]*TPbuy,NULL);
           }
        }
     }

   if(EachPositionsTotal("sell") < positions/2)
     {
      if(signal =="sell")
        {
         if((Bid - low[0]*TPsell) > 25*_Point  && (high[0]*SLsell- Bid) > SL*_Point)
           {
            trade.Sell(lot,NULL,Bid,high[0]*SLsell,low[0]*TPsell,NULL);
           }
        }
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

//+------------------------------------------------------------------+
