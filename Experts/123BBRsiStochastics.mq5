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
input int RSIPeriod,RSIPriceType,RSIStopCri,RSIUntradableCri;

int StochasticIndicator;
double StochasticK[],StochasticD[];
input int StochasticPeriod,ma_method,k,slowing,StochasticKCri,StochasticDCri;

input int SL;
int LongTrend,ShortTrend = 0;

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

   RSIIndicator = iRSI(_Symbol,Timeframe(StochasticPeriod+RSIPeriod),14,RSIPriceType);
   StochasticIndicator = iStochastic(_Symbol,Timeframe(StochasticPeriod),k,3,slowing,StochasticMethod,STO_LOWHIGH);

   ArraySetAsSeries(RSI,true);
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

   CopyBuffer(RSIIndicator, 0,0,1, RSI);
   CopyBuffer(StochasticIndicator, 0,0,2, StochasticK);
   CopyBuffer(StochasticIndicator, 1,0,2, StochasticD);

   if(StochasticK[0] > 100-StochasticKCri)
     {
      CloseAllBuyPositions();
     }

   if(StochasticK[0] < StochasticKCri)
     {
      CloseAllSellPositions();
     }


   if(isPositionCLosed()){
      return;
   }

   if(isUntradable())
     {
      return;
     }

   if(RSI[0] > 100-(RSIStopCri+RSIUntradableCri) || RSI[0] < RSIStopCri+RSIUntradableCri)
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
      trade.Buy(lot,NULL,Ask,Ask-SL*_Point,Ask+10000*_Point,NULL);
     }

   if(EachPositionsTotal("sell") < positions/2 && signal=="sell")
     {
      trade.Sell(lot,NULL,Bid,Bid+SL*_Point,Bid-10000*_Point,NULL);
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
bool isPositionCLosed()
  {
   bool result = false;
   if(RSI[0] > 100-RSIStopCri)
     {
      CloseAllSellPositions();
      result = true;
     }
   else
      if(RSI[0] < RSIStopCri)
        {
         CloseAllBuyPositions();
         result = true;
        }

   if(StochasticD[1] <= 80 && StochasticD[0]>80)
     {
      LongTrend++;
      ShortTrend = 0;
      if(LongTrend >1)
        {
         CloseAllSellPositions();
         result = true;
        }
     }
   else
      if(StochasticD[1]>=20 &&StochasticD[0]<20)
        {
         ShortTrend++;
         LongTrend = 0;
         if(ShortTrend>1)
           {
            CloseAllBuyPositions();
            result = true;
           }
        }
   return result;
  }
//+------------------------------------------------------------------+
