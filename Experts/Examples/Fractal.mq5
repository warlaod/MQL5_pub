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
CTrade trade;

input int indparam1 = 0;
input int indparam2 = 0;
input int positions = 1;

double lot = 0.10;
double fractal_up[],fractal_down[];
int n;
double FractalDown[],FractalUp[];
double UpFractal,LowFractal;
int Indicator;
input int FractalPeriod;
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
     
   Indicator = iFractals(_Symbol, Timeframe(FractalPeriod));
   ArraySetAsSeries(FractalUp,true);
   ArraySetAsSeries(FractalDown,true);

   return(INIT_SUCCEEDED);
  }

void OnTick()
  {
   if(isTooBigSpread(2))
     {
      return;
     }
   MqlDateTime dt;
   TimeToStruct(TimeLocal(),dt);

     
   double Bid=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
   double Ask=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
   string signal = "";



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+


   CopyBuffer(Indicator,0,0,50,FractalUp);
   CopyBuffer(Indicator,1,0,50,FractalDown);

   

   for(n=0; n<50; n++)
     {
      if(FractalUp[n]!=EMPTY_VALUE)
         break;
     }
   UpFractal=FractalUp[n];
   
   for(n=0; n<50; n++)
     {
      if(FractalDown[n]!=EMPTY_VALUE)
         break;
     }
   LowFractal=FractalDown[n];
   
   if(EachPositionsTotal("buy") < positions/2)
     {
      if(signal =="buy")
        {
         if((UpFractal*TPbuy - Ask) > 25*_Point && (Ask - LowFractal*SLbuy) > 9*_Point)
           {
            trade.Buy(lot,NULL,Ask,LowFractal*SLbuy,UpFractal*TPbuy,NULL);
           }
        }
     }

   if(EachPositionsTotal("sell") < positions/2)
     {
      if(signal =="sell")
        {
         if((Bid - LowFractal*TPsell) > 25*_Point  && (UpFractal*SLsell- Bid) > 9*_Point)
           {
            trade.Sell(lot,NULL,Bid,UpFractal*SLsell,LowFractal*TPsell,NULL);
           }
        }
     }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

  }
//+------------------------------------------------------------------+
