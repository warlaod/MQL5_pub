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
input int MIN;
input int positions,denom;
double lot = 0.10;
double  Bid,Ask;

int AMAIndicator;
double AMA[];
input int AMAPeriod,AMABufferRange,AMAPriceType,AMATrendCri;

int StochasticIndicator;
double StochasticK[],StochasticD[];
input int StochasticPeriod,ma_method,k,slowing,StochasticKCri,StochasticDCri;

string signal,lasttrade;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   ENUM_MA_METHOD StochasticMethod;
   switch(ma_method)
     {
      case 0:
         StochasticMethod = MODE_SMA;
         break;
      case 1:
         StochasticMethod = MODE_EMA;
         break;
      case 2:
         StochasticMethod = MODE_SMMA;
         break;
      case 3:
         StochasticMethod = MODE_LWMA;
         break;
     }
   AMAIndicator = iAMA(_Symbol,Timeframe(AMAPeriod),9,2,30,0,AMAPriceType);
   StochasticIndicator = iStochastic(_Symbol,Timeframe(StochasticPeriod),k,3,slowing,StochasticMethod,STO_LOWHIGH);

   ArraySetAsSeries(AMA,true);
   ArraySetAsSeries(StochasticK,true);
   ArraySetAsSeries(StochasticD,true);

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

   CopyBuffer(AMAIndicator, 0,0,AMABufferRange, AMA);
   CopyBuffer(StochasticIndicator, 0,0,2, StochasticK);
   CopyBuffer(StochasticIndicator, 1,0,2, StochasticD);

   if(StochasticK[0] > 100-StochasticKCri)
     {
      TrailingStop(Ask,Bid,10*_Point,10*_Point,true,false);
     }

   if(StochasticK[0] < StochasticKCri)
     {
      TrailingStop(Ask,Bid,10*_Point,10*_Point,false,true);
     }
     
   double AMATrend = (AMA[0] - AMA[AMABufferRange-1])/AMABufferRange;
   
   if(AMATrend > AMATrendCri*_Point){
      CloseAllSellPositions();
      return;
   }
   if(AMATrend < -AMATrendCri*_Point){
      CloseAllBuyPositions();
      return;
   }
   
   if(isUntradable())
     {
      return;
     }


   signal = "";

   if(StochasticD[1] > 100-StochasticDCri)
     {
      if(StochasticK[1]-StochasticD[1] > 0 &&  StochasticK[0]-StochasticD[0] < 0)
        {
         signal="sell";
        }
     }

   if(StochasticD[1] > StochasticDCri)
     {
      if(StochasticK[1]-StochasticD[1] < 0 &&  StochasticK[0]-StochasticD[0] > 0)
        {
         signal="buy";
        }
     }


   if(signal =="buy" && lasttrade != "buy")
     {
      trade.Buy(lot,NULL,Ask,Ask-1000*_Point,Ask+500*_Point,NULL);
      lasttrade = "buy";
     }

   if(signal =="sell" && lasttrade != "sell")
     {
      trade.Sell(lot,NULL,Bid,Bid+1000*_Point,Bid-500*_Point,NULL);
      lasttrade = "sell";
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

   if(isTooBigSpread(2))
     {
      return true;
     }
   return false;
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
