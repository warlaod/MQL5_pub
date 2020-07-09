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
input int positions,denom,spread;
double lot = 0.10;
double  Bid,Ask;
bool tradable = true;

int IchimokuIndicator;
double Tenkan[],Kijun[],Senkou1[],Senkou2[],Chikou[];
input int IchimokuPeriod,SenkouCri,KijunCri;
input double TPCoef;

string signal,lasttrade;
int tradesignal;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   EventSetTimer(300);
   IchimokuIndicator = iIchimoku(_Symbol,Timeframe(IchimokuPeriod),9,26,52);

   ArraySetAsSeries(Tenkan,true);
   ArraySetAsSeries(Kijun,true);
   ArraySetAsSeries(Senkou1,true);
   ArraySetAsSeries(Senkou2,true);
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

   lot =SetLot(denom);

   CopyBuffer(IchimokuIndicator, 0,0,2, Tenkan);
   CopyBuffer(IchimokuIndicator, 1,0,2, Kijun);
   CopyBuffer(IchimokuIndicator, 2,0,2, Senkou1);
   CopyBuffer(IchimokuIndicator, 3,0,2, Senkou2);
   CopyRates(_Symbol,_Period,0,26,Price);
   
   


   if(tradable == false || isTooBigSpread(spread))
     {
      return;
     }
   

   signal = "";

if( MathAbs(Senkou1[1] - Senkou2[1]) < SenkouCri*_Point || MathAbs(Senkou1[1] - Kijun[1]) < KijunCri*_Point){
   return;
}

   if(Tenkan[1] > Kijun[1] && Kijun[1] > Senkou1[1] && Senkou1[1] > Senkou2[1])
     {
      signal = "buy";
     }
  else if(Tenkan[1] < Kijun[1] && Kijun[1] < Senkou1[1] && Senkou1[1] < Senkou2[1])
     {
      signal = "sell";
     }


   double TPSLline = MathAbs(Tenkan[0]-Kijun[0]);

   if(EachPositionsTotal("buy") < positions/2 && signal=="buy")
     {
      if(isNotInvalidTrade(Senkou1[1], Ask+TPSLline*TPCoef, Ask,true))
        {
         trade.Buy(lot,NULL,Ask,Senkou1[1],Ask+TPSLline*TPCoef,NULL);
        }
     }

   if(EachPositionsTotal("sell") < positions/2 && signal=="sell")
     {
      if(isNotInvalidTrade(Senkou1[1],Bid-TPSLline*TPCoef, Bid,false))
        {
         trade.Sell(lot,NULL,Bid,Senkou1[1],Bid-TPSLline*TPCoef,NULL);
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
   return testingNormal();

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
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
