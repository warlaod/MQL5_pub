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
CTrade trade;

string signal;
input int SL;
input int MIN;
input int denom;
input int positions;
input double TPbuy,SLbuy,TPsell,SLsell;
double lot = 0.10;
MqlDateTime dt;

double fractal_up[],fractal_down[];
int n;
double FractalDown[],FractalUp[];
double LowFractal_new,LowFractal_old,UpFractal_new,UpFractal_old;
int Indicator;
double UpDif,LowDif;
input double SLCoefLong,TPCoefLong,SLCoefShort,TPCoefShort;
input int FractalPeriod;
 

double RSI[];
input int RSIPeriod,RSIParam,RSIPriceType;
int RSIIndicator;
input int RSILongCri,RSIShortCri;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   Indicator = iFractals(_Symbol, Timeframe(FractalPeriod));
   ArraySetAsSeries(FractalUp,true);
   ArraySetAsSeries(FractalDown,true);


   RSIIndicator =iRSI(_Symbol,Timeframe(RSIPeriod),RSIParam,RSIPriceType);
   ArraySetAsSeries(RSI,true);

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


   if(isTooBigSpread(2))
     {
      return;
     }
   if(isNotEnoughMoney())
     {
      return;
     }

   lot =SetLot(denom);


   double Bid=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
   double Ask=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);

   
   CopyRates(_Symbol,_Period,0,3,PriceInfo);

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
   UpFractal_new=FractalUp[n];

   for(n=0; n<50; n++)
     {
      if(FractalDown[n]!=EMPTY_VALUE)
         break;
     }
   LowFractal_new=FractalDown[n];



   CopyBuffer(RSIIndicator,0,0,2,RSI);



   signal = "";

   if(UpFractal_new > UpFractal_old && LowFractal_new > LowFractal_old)
     {
      if(RSI[1] < RSI[0] && RSI[1] < RSILongCri)
        {
         signal = "buy";
        }
     }

   if(UpFractal_new < UpFractal_old && LowFractal_new < LowFractal_old)
     {
      if(RSI[1] > RSI[0] && RSI[1] > RSIShortCri)
        {
         signal = "sell";
        }
     }




   if(EachPositionsTotal("buy") < positions/2 && signal=="buy")
     {
      UpDif = MathAbs(UpFractal_new-UpFractal_old);
      if(UpDif*TPCoefLong > 25*_Point && UpDif*SLCoefLong > SL*_Point)
        {
         trade.Buy(lot,NULL,Ask,Ask-UpDif*SLCoefLong,Ask+UpDif*TPCoefLong,NULL);
        }
     }


   if(EachPositionsTotal("sell") < positions/2 && signal=="sell")
     {
      LowDif = MathAbs(LowFractal_new-LowFractal_old);
      if(Bid+LowDif*SLCoefShort > 25*_Point  && Bid-LowDif*TPCoefShort > SL*_Point)
        {
         trade.Sell(lot,NULL,Bid,Bid+LowDif*TPCoefShort,Bid-LowDif*SLCoefShort,NULL);
        }
     }

   if(UpFractal_old != UpFractal_new)
     {
      UpFractal_old = UpFractal_new;
     }
   if(LowFractal_old != LowFractal_new)
     {
      LowFractal_old = LowFractal_new;
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
