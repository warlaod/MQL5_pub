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

int RSIIndicator;
double RSI[];
input int RSIPeriod,RSIPriceType,RSIUntradableCri;

int StochasticIndicator;
double StochasticK[],StochasticD[];
input int StochasticPeriod,ma_method,k,slowing,StochasticDCri;

int ATRIndicator;
input double TPCoef,SLCoef; 
double ATR[];

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

   RSIIndicator = iRSI(_Symbol,Timeframe(RSIPeriod),14,RSIPriceType);
   StochasticIndicator = iStochastic(_Symbol,Timeframe(StochasticPeriod),k,3,slowing,StochasticMethod,STO_LOWHIGH);
   
   ATRIndicator = iATR(_Symbol,Timeframe(StochasticPeriod),14);
   
   ArraySetAsSeries(RSI,true);
   ArraySetAsSeries(StochasticK,true);
   ArraySetAsSeries(StochasticD,true);
   ArraySetAsSeries(ATR,true);

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

   CopyBuffer(RSIIndicator, 0,0,1, RSI);
   CopyBuffer(StochasticIndicator, 0,0,2, StochasticK);
   CopyBuffer(StochasticIndicator, 1,0,2, StochasticD);
   CopyBuffer(ATRIndicator, 0,0,1, ATR);
   
   
   if(RSI[0] > 100-RSIUntradableCri || RSI[0] < RSIUntradableCri)
     {
      return;
     }else if(RSI[0] < RSIUntradableCri
     
     
   if(isUntradable())
     {
      return;
     }

   if(RSI[0] > 100-RSIUntradableCri || RSI[0] < RSIUntradableCri)
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

   if(StochasticD[1] < StochasticDCri)
     {
      if(StochasticK[1]-StochasticD[1] < 0 &&  StochasticK[0]-StochasticD[0] > 0)
        {
         signal="buy";
        }
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
   return testingScalp();

  }
//+------------------------------------------------------------------+
bool isUntradable()
  {
   if(isNotEnoughMoney()){
      return true;
   }
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
