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
double UpFractal,LowFractal;
int Indicator;
input int FractalPeriod;


double Osma[];
int OsmaIndicator;
input int OsmaPeriod;
input int Osmapricetype;
input double OsmaCriPL;
input double OsmaCriMI;

double WPR[];
int WPRIndicator;
input int WPRPeriod,WPRparam;
input int WPRLongDec,WPRShortDec;
  

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   Indicator = iFractals(_Symbol, Timeframe(FractalPeriod));
   ArraySetAsSeries(FractalUp,true);
   ArraySetAsSeries(FractalDown,true);

   OsmaIndicator = iOsMA(_Symbol,Timeframe(OsmaPeriod),12,26,9,Osmapricetype);
   ArraySetAsSeries(Osma,true);
     
   WPRIndicator = iWPR(_Symbol,Timeframe(WPRPeriod),WPRparam);
   ArraySetAsSeries(WPR,true);

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


   CopyBuffer(OsmaIndicator,0,0,2,Osma);
   CopyBuffer(WPRIndicator,0,0,3,WPR);

   signal = "";

   if(Osma[0] > 0 && Osma[0] > Osma[1] && Osma[0] > OsmaCriPL && WPR[0] < -WPRLongDec)
     {
      signal= "buy";
     }
   else
      if(Osma[0] < 0 && Osma[0] < Osma[1] && Osma[0] < -OsmaCriMI && WPR[0] > -WPRShortDec)
        {
         signal= "sell";
        }

   if(EachPositionsTotal("buy") < positions/2)
     {
      if(signal =="buy")
        {
         if((UpFractal*TPbuy - Ask) > 25*_Point && (Ask - LowFractal*SLbuy) > SL*_Point)
           {
            trade.Buy(lot,NULL,Ask,LowFractal*SLbuy,UpFractal*TPbuy,NULL);
           }
        }
     }

   if(EachPositionsTotal("sell") < positions/2)
     {
      if(signal =="sell")
        {
         if((Bid - LowFractal*TPsell) > 25*_Point  && (UpFractal*SLsell- Bid) > SL*_Point)
           {
            trade.Sell(lot,NULL,Bid,UpFractal*SLsell,LowFractal*TPsell,NULL);
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
   return testingNormal();

  }