//+------------------------------------------------------------------+
//|                                                     templete.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"





#include <Trade\Trade.mqh>
#include <Original\prices.mqh>
#include <Original\positions.mqh>
#include <Original\period.mqh>
#include <Original\account.mqh>
#include <Original\Ontester.mqh>
CTrade trade;


input int positions;
input double TPbuy,SLbuy,TPsell,SLsell;
double lot = 0.10;
MqlDateTime dt;
double high[],low[];
input double BBDev;
input int BBPeriod,BBParam,BBPricetype;
int Indicator;

int AMAIndicator;
double AMA[];
input int AMAPeriod,AMAPricetype,AMAParam,AMAFastParam,AMASlowParam;

int TEMAIndicator;
double TEMA[];
input int TEMAPeriod,TEMAPricetype,TEMAParam;


input int MIN;
string signal;
double  Bid,Ask;

input int SL;
input int Trades,Min,Stops;
input int denom;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   Indicator =  iBands(_Symbol,Timeframe(BBPeriod),BBParam,0,BBDev,BBPricetype);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
  
   AMAIndicator = iAMA(_Symbol,Timeframe(AMAPeriod),AMAParam,AMAFastParam,AMAFastParam+AMASlowParam,0,AMAPricetype);
   ArraySetAsSeries(AMA,true);

   TEMAIndicator = iDEMA(_Symbol,Timeframe(AMAPeriod),TEMAParam,0,TEMAPricetype);
   ArraySetAsSeries(TEMA,true);
   
   iCustom(_Symbol,_Period,"BBandwidth",20,0,2);

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

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

   lot =SetLot(denom);




   Bid=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
   Ask=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);

   CopyBuffer(TEMAIndicator, 0,0,2, TEMA);
   CopyBuffer(AMAIndicator, 0,0,2, AMA);
   
   CopyBuffer(Indicator, 1,0,2, high);
   CopyBuffer(Indicator, 2,0,2, low);
   
   signal = "";

   if(AMA[1] > TEMA[1] && TEMA[0] > AMA[0])
     {
      signal= "buy";
     }
   else
      if(AMA[1] < TEMA[1] && TEMA[0] < AMA[0])
        {
         signal= "sell";
        }



   if(EachPositionsTotal("buy") < positions/2 && signal=="buy")
     {
      if((high[0]*TPbuy - Ask) > 20*_Point && (Ask - low[0]*SLbuy) > SL*_Point)
        {
         trade.Buy(lot,NULL,Ask,low[0]*SLbuy,high[0]*TPbuy,NULL);
        }
     }

   if(EachPositionsTotal("sell") < positions/2 && signal =="sell")
     {
      if((Bid - low[0]*TPsell) > 20*_Point  && (high[0]*SLsell- Bid) > SL*_Point)
        {
         trade.Sell(lot,NULL,Bid,high[0]*SLsell,low[0]*TPsell,NULL);
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
   return testingScalp();

  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
