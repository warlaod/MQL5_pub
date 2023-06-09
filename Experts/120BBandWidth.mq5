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
input int MIN;
input double BBDev;
input int BBPeriod,BBParam,BBPricetype;
input int positions,denom;
input double TPLong,TPShort;
double lot = 0.10;
double  Bid,Ask;

int BBIndicator;
double BBhigh[],BBlow[],BBmiddle[];

input int TrailingSL;
input int arrayRange,arrayRangeDev;
input double BWHighCri,BWLowCri;
int BBandWidthIndicator;
double  BandWidth[];
MqlRates Price[];
string signal;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   ArraySetAsSeries(BBhigh,true);
   ArraySetAsSeries(BBlow,true);
   ArraySetAsSeries(BBmiddle,true);
   ArraySetAsSeries(BandWidth,true);
   ArraySetAsSeries(Price,true);
   BBIndicator =  iBands(_Symbol,Timeframe(BBPeriod),BBParam,0,BBDev,BBPricetype);
   ArrayResize(BandWidth,arrayRange);

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   Bid=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
   Ask=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);



   lot =SetLot(denom);


   CopyBuffer(BBIndicator, 0,0,arrayRange, BBmiddle);
   CopyBuffer(BBIndicator, 1,0,arrayRange, BBhigh);
   CopyBuffer(BBIndicator, 2,0,arrayRange, BBlow);
   CopyRates(_Symbol,_Period,0,3,Price);

   for(int i = 0; i < ArraySize(BBmiddle); i++)
     {
      BandWidth[i] = (BBhigh[i] - BBlow[i]) *1000;
     }

   signal = "";


   if(LowestVal < BWHighCri && LowestNum < arrayRange/arrayRangeDev)
     {
      if(BBhigh[1] < Price[1].close && BBhigh[2] < Price[2].close)
        {
         signal = "buy";
        }
      if(BBlow[1] > Price[1].close && BBhigh[2] > Price[2].close)
        {
         signal = "sell";
        }
     }


   if(EachPositionsTotal("buy") < positions/2 && signal =="buy")
     {
      trade.Buy(lot,NULL,Ask,BBmiddle[0],BBhigh[0]+TPLong,NULL);
     }

   if(EachPositionsTotal("sell") < positions/2 && signal =="sell")
     {
      trade.Sell(lot,NULL,Bid,BBmiddle[0],BBlow[0]*TPShort,NULL);
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
bool isUntradable()
  {
   TimeToStruct(TimeCurrent(),dt);
   if(dt.day_of_week == FRIDAY)
     {
      if((dt.hour == 22 && dt.min > MIN) || dt.hour == 23)
        {
         CloseAllBuyPositions();
         CloseAllSellPositions();
         return true;
        }
     }

   if(isTooBigSpread(2))
     {
      return true;
     }
   return false;

  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
