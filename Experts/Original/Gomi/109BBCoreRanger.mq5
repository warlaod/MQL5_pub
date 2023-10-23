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
input int BBPeriod,BBParamShort,BBParamLong,BBPricetype;
input int positions,denom;
input double TPbuy;
input double SLbuy;
input double TPsell;
input double SLsell;
input int SL;
double lot = 0.10;
int BBShortIndicator,BBLongIndicator;
double  Bid,Ask;
double highShort[],lowShort[],middleShort[];
double highLong[],lowLong[],middleLong[];
MqlRates Price[];

string signal;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   ArraySetAsSeries(highShort,true);
   ArraySetAsSeries(lowShort,true);
   ArraySetAsSeries(middleShort,true);
   BBShortIndicator =  iBands(_Symbol,Timeframe(BBPeriod),BBParamShort,0,BBDev,BBPricetype);
   BBLongIndicator =  iBands(_Symbol,Timeframe(BBPeriod),BBParamShort+BBParamLong,0,BBDev,BBPricetype);


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

    lot =SetLot(denom);

   Bid=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
   Ask=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);

   CopyBuffer(BBShortIndicator, 1,0,3, highShort);
   CopyBuffer(BBShortIndicator, 2,0,3, lowShort);

   CopyBuffer(BBLongIndicator, 0,0,2, middleLong);
   CopyBuffer(BBLongIndicator, 1,0,2, highLong);
   CopyBuffer(BBLongIndicator, 2,0,2, lowLong);

   CopyRates(_Symbol,_Period,0,3,Price);
   
   signal = "";

   if(highLong[0] > Price[0].close && middleLong[0] < Price[0].close)
     {
      if(Price[2].close > highShort[2] && highShort[1] > Price[1].close && highShort[0] > Price[0].close)
        {
         signal = "buy";
        }
     }
     
   else if(lowLong[0] < Price[0].close && middleLong[0] > Price[0].close)
     {
      if(Price[2].close < lowShort[2] && lowShort[1] < Price[1].close && lowShort[0] < Price[0].close)
        {
         signal = "sell";
        }
     }

   if(EachPositionsTotal("buy") < positions/2)
     {
      if(signal =="buy")
        {
         if((highShort[0]*TPbuy - Ask) > 25*_Point && (Ask - lowShort[0]*SLbuy) > SL*_Point)
           {
            trade.Buy(lot,NULL,Ask,lowShort[0]*SLbuy,highShort[0]*TPbuy,NULL);
           }
        }
     }

   if(EachPositionsTotal("sell") < positions/2)
     {
      if(signal =="sell")
        {
         if((Bid - lowShort[0]*TPsell) > 25*_Point  && (highShort[0]*SLsell- Bid) > SL*_Point)
           {
            trade.Sell(lot,NULL,Bid,highShort[0]*SLsell,lowShort[0]*TPsell,NULL);
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
