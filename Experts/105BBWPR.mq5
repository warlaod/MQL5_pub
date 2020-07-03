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
#include <Original\Ontester.mqh>
CTrade trade;

MqlDateTime dt;
input int MIN;
input double BBDev;
input int BBPeriod,BBParam,BBPricetype;
input int positions,denom;
input double TPbuy;
input double SLbuy;
input double TPsell;
input double SLsell;
input int SL;
double lot = 0.10;
int Indicator;
double  Bid,Ask;
double high[],low[];

double RSI[];
int RSIIndicator;
input int RSIPeriod,RSIParam,RSIPricetype,RSILongCri,RSIShortCri;
string signal;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   Indicator =  iBands(_Symbol,Timeframe(BBPeriod),BBParam,0,BBDev,BBPricetype);
   
   OBV
   
   ArraySetAsSeries(RSI,true);
   RSIIndicator =iRSI(_Symbol,Timeframe(RSIPeriod),RSIParam,RSIPricetype);


   return(INIT_SUCCEEDED);
  }
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

   if(isNotEnoughMoney())
     {
      return;
     }
   if(isTooBigSpread(2))
     {
      return;
     }
     
   SetLot(denom);

   Bid=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
   Ask=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);

   CopyBuffer(Indicator, 0,0,2, high);
   CopyBuffer(Indicator, 1,0,2, low);

   if(high[0] == EMPTY_VALUE || low[0] == EMPTY_VALUE)
     {
      return;
     }


   CopyBuffer(RSIIndicator,0,0,1,RSI);

   if(RSI[0] < RSILongCri)
     {
      signal="buy";

     }

   if(RSI[0] > RSIShortCri)
     {
      signal="sell";
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
