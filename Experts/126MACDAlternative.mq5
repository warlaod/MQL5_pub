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

int MacdShortIndicator,MacdLongIndicator,ATRIndicator;
input int MacdLongPeriod,MacdShortPeriod,MacdPriceType;
input double TPCoef,SLCoef,LongMacdSignalCri,ShortMacdCri;
double LongMacd[],LongMacdSignal[],ShortMacd[],ShortMacdSignal[],ATR[];
input int spread;

bool tradable = true;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   EventSetTimer(1800);
//EmaIndicator = iMA(_Symbol,Timeframe(MacdPeriod+EmaPeriod),10,0,MODE_EMA,EmaPriceType);
   MacdShortIndicator = iMACD(_Symbol,Timeframe(MacdShortPeriod),12,26,9,MacdPriceType);
   MacdLongIndicator = iMACD(_Symbol,Timeframe(MacdLongPeriod),12,26,9,MacdPriceType);
   ATRIndicator = iATR(_Symbol,Timeframe(MacdShortPeriod),14);
//ArraySetAsSeries(Macd,true);
//ArraySetAsSeries(MacdSignal,true);
   ArraySetAsSeries(ShortMacd,true);
   ArraySetAsSeries(ShortMacdSignal,true);
   ArraySetAsSeries(LongMacd,true);
   ArraySetAsSeries(LongMacdSignal,true);
   ArraySetAsSeries(ATR,true);
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(isTooBigSpread(spread) || tradable == false)
     {
      return;
     }
   double Bid=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
   double Ask=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
   signal = "";
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   CopyBuffer(MacdShortIndicator,0,0,3,ShortMacd);
   CopyBuffer(MacdShortIndicator,1,0,3,ShortMacdSignal);
   CopyBuffer(MacdLongIndicator,0,0,3,LongMacd);
   CopyBuffer(MacdLongIndicator,1,0,3,LongMacdSignal);
   CopyBuffer(ATRIndicator,0,0,1,ATR);

   double LongHistogram[3];
   double ShortHistogram[3];
   for(int i=0; i<3; i++)
     {
      LongHistogram[i] = LongMacd[i] - LongMacdSignal[i];
      ShortHistogram[i] = ShortMacd[i] - ShortMacdSignal[i];
     }
   
   if(MathAbs(LongMacdSignal[1]) < LongMacdSignalCri || MathAbs(ShortMacd[1]) < ShortMacdCri){
      return;
   }

   signal = "";
   if(LongHistogram[1] > 0 && LongMacd[1] > 0)
     {
      signal ="buybuy";
     }
   else
      if(LongHistogram[1] < 0 && LongMacd[1] < 0)
        {
         signal ="sellsell";
        }

   if(ShortHistogram[2] < 0 && ShortHistogram[1] > 0 && ShortMacd[1] < 0 && signal == "buybuy")
     {
      signal = "buy";
     }
   else
      if(ShortHistogram[2] > 0 && ShortHistogram[1] < 0 && ShortMacd[1] > 0 && signal == "sellsell")
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
