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
input int positions,denom;
double lot = 0.10;
double  Bid,Ask;

int IchimokuIndicator;
double Tenkan[],Kijun[],Senkou1[],Senkou2[],Chikou[];
input int IchimokuPeriod,MomiaiRange,MomiaiCri;

string signal,lasttrade;
int tradesignal;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
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
   CopyBuffer(IchimokuIndicator, 1,0,MomiaiRange, Kijun);
//CopyBuffer(IchimokuIndicator, 2,0,1, Senkou1);
//CopyBuffer(IchimokuIndicator, 3,0,1, Senkou2);
  //CopyRates(_Symbol,_Period,0,26,Price);



   if(isUntradable())
     {
      return;
     }
     
   if(MathAbs(Kijun[0] - Kijun[MomiaiRange-1]) <= MomiaiCri*_Point){
      return;
   }
   

   signal = "";

   if(Kijun[0] > Tenkan[0] && Tenkan[1] > Tenkan[0])
     {
      signal = "sell";
     }

   if(Kijun[0] < Tenkan[0] && Tenkan[1] < Tenkan[0])
     {
      signal = "buy";
     }



   double TPSLline = MathAbs(Tenkan[0]-Kijun[0]);

   if(EachPositionsTotal("buy") < positions/2 && signal=="buy")
     {
      if(isNotInvalidTrade(Kijun[0], Ask+TPSLline, Ask,true))
        {
         trade.Buy(lot,NULL,Ask,Kijun[0],Ask+TPSLline,NULL);
        }
     }

   if(EachPositionsTotal("sell") < positions/2 && signal=="sell")
     {
      if(isNotInvalidTrade(Kijun[0],Bid-TPSLline, Bid,false))
        {
         trade.Sell(lot,NULL,Bid,Kijun[0],Bid-TPSLline,NULL);
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
   
   if(isNotEnoughMoney()){
      return true;
   }

   if(isTooBigSpread(2))
     {
      return true;
     }
   

   return false;
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
