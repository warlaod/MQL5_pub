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
input double BBDev;
input int BBPeriod;
input ENUM_TIMEFRAMES BBTimeframe;
input ENUM_APPLIED_PRICE BBAplied_price;
input int positions,denom;
double lot = 0.10;
double  Bid,Ask;

int BBIndicator;
double BBhigh[],BBlow[],BBmiddle[];

input int BandWidthRange;
input int PriceCri;
input double BWDiffCri,TPCoef;
int BBandWidthIndicator;
double  BandWidth[];
MqlRates Price[];
input int spread;
string signal;

bool tradable = false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   EventSetTimer(300);
   ArraySetAsSeries(BBhigh,true);
   ArraySetAsSeries(BBlow,true);
   ArraySetAsSeries(BBmiddle,true);
   ArraySetAsSeries(BandWidth,true);
   ArraySetAsSeries(Price,true);
   BBIndicator =  iBands(_Symbol,BBTimeframe,BBPeriod,0,BBDev,BBAplied_price);
   ArrayResize(BandWidth,BandWidthRange);

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


   CopyBuffer(BBIndicator, 0,0,2, BBmiddle);
   CopyBuffer(BBIndicator, 1,0,BandWidthRange, BBhigh);
   CopyBuffer(BBIndicator, 2,0,BandWidthRange, BBlow);
   CopyRates(_Symbol,BBTimeframe,0,3,Price);

   signal = "";
   if(tradable == false || isTooBigSpread(spread))
     {
      return;
     }

   for(int i=0; i < BandWidthRange; i++)
     {
      BandWidth[i] = (BBhigh[i] - BBlow[i]);
     }
   SearchLowest(BandWidth);

   if(BandWidth[1]/LowestVal < BWDiffCri)
      return;




   if(Price[1].high > BBhigh[1] && Price[1].close - Price[1].open > 0 && Price[0].close > Price[1].close)
     {
      if(MathAbs(Price[1].high - Price[1].close) > PriceCri*_Point)
        {
         return;
        }
      signal = "buy";
     }
   else
      if(Price[1].low < BBlow[1] && Price[1].close - Price[1].open < 0 && Price[0].close < Price[1].close)
        {
         if(MathAbs(Price[1].low - Price[1].close) > PriceCri*_Point)
           {
            return;
           }
         signal = "sell";
        }

   if(EachPositionsTotal("buy") < positions/2 && signal =="buy")
     {
      trade.Buy(lot,NULL,Ask,BBmiddle[1],BBhigh[1]+BandWidth[1]*TPCoef,NULL);
     }

   if(EachPositionsTotal("sell") < positions/2 && signal =="sell")
     {
      trade.Sell(lot,NULL,Bid,BBmiddle[1],BBlow[1]-BandWidth[1]*TPCoef,NULL);
     }

  }
//+------------------------------------------------------------------+
double OnTester()
  {

   if(!setVariables())
     {
      return -99999999;
     }
   return testingScalpMoreTrade();

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

   TimeToStruct(TimeCurrent(),dt);
   if(dt.day_of_week == FRIDAY)
     {
      if((dt.hour == 22 && dt.min > 15) || dt.hour == 23)
        {
         CloseAllBuyPositions();
         CloseAllSellPositions();
         tradable = false;
         return;
        }
     }

   int cant_hour[] = {};
   if(!isTradableJP(cant_hour,dt.hour))
     {
      tradable = false;
      return;
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
