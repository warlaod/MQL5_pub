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

string signal;
input int SL;
input int MIN;
input int denom;
input int positions;
double lot = 0.10;
MqlDateTime dt;

/*
int EmaIndicator
input int EmaPeriod,EmaPriceType;
double Ema[];
*/

int OsmaShortIndicator,ATRIndicator;
input int OsmaShortPeriod;
input double TPCoef,SLCoef;
input double MacdCri;
double OsmaShort[],ATR[];

int RSIIndicator;
double RSI[];
input int RSIPeriod,RSIPriceType,RSIUntradableCri;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
//EmaIndicator = iMA(_Symbol,Timeframe(MacdPeriod+EmaPeriod),10,0,MODE_EMA,EmaPriceType);
//MacdIndicator = iMACD(_Symbol,Timeframe(MacdPeriod),12,26,9,MacdPriceType);
   OsmaShortIndicator = iOsMA(_Symbol,Timeframe(OsmaShortPeriod),12,26,9,PRICE_CLOSE);
   RSIIndicator = iRSI(_Symbol,Timeframe(RSIPeriod),14,PRICE_CLOSE);
   ATRIndicator = iATR(_Symbol,Timeframe(OsmaShortPeriod),14);
//ArraySetAsSeries(Macd,true);
//ArraySetAsSeries(MacdSignal,true);
   ArraySetAsSeries(OsmaShort,true);
   ArraySetAsSeries(ATR,true);
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {

   lot =SetLot(denom);
   double Bid=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
   double Ask=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
   signal = "";
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//CopyBuffer(EmaIndicator,0,0,2,Ema);
//CopyBuffer(MacdIndicator,0,0,30,Macd);
//CopyBuffer(MacdIndicator,1,0,2,MacdSignal);
   CopyBuffer(OsmaShortIndicator,0,0,2,OsmaShort);
   CopyBuffer(ATRIndicator,0,0,1,ATR);



   SearchHighest(OsmaShort);
   SearchLowest(OsmaShort);
   

   
   if(isUntradable())
     {
      return;
     }

   signal = "";


   if(OsmaShort[1] < 0 && OsmaShort[0] > 0 && RSI[0] < RSIUntradableCri)
     {
      signal = "buy";
     }
   else
      if(OsmaShort[1] > 0 && OsmaShort[0] < 0 && RSI[0] > 100 - RSIUntradableCri)
        {
         signal = "sell";
        }

   if(EachPositionsTotal("buy") < positions/2 && signal=="buy")
     {
      trade.Buy(lot,NULL,Ask,Ask-ATR[0]*SLCoef,Ask+ATR[0]*TPCoef,NULL);
     }

   if(EachPositionsTotal("sell") < positions/2 && signal=="sell")
     {
      trade.Sell(lot,NULL,Bid,Bid+ATR[0]*SLCoef,Bid-ATR[0]*TPCoef,NULL);
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
//|                                                                  |
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
   if(isNotEnoughMoney())
     {
      return true;
     }
   return false;

  }
//+------------------------------------------------------------------+
