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

int TEMAShortIndicator,TEMAMiddleIndicator,TEMALongIndicator;
double TEMAShort[],TEMAMiddle[],TEMALong[];
input int MaPeriod,TEMAPricetype,MaParamShort,MaParamMiddle,MaParamLong;


input int MIN;
string signal;
double  Bid,Ask;

input int SL;
input int Trades,Min,Stops;
input int denom;
input int ma_method;
ENUM_MA_METHOD Ma_Mehod;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   switch(ma_method)
     {
      case 0:
         Ma_Mehod = MODE_SMA;
         break;
      case 1:
         Ma_Mehod = MODE_EMA;
         break;
      case 2:
         Ma_Mehod = MODE_SMMA;
         break;
      case 3:
         Ma_Mehod = MODE_LWMA;
         break;
     }
   TEMAShortIndicator = iMA(_Symbol,Timeframe(MaPeriod),MaParamShort,0,Ma_Mehod,TEMAPricetype);
   ArraySetAsSeries(TEMAShort,true);

   TEMAMiddleIndicator = iMA(_Symbol,Timeframe(MaPeriod),MaParamShort+MaParamMiddle,0,Ma_Mehod,TEMAPricetype);
   ArraySetAsSeries(TEMAMiddle,true);

   TEMALongIndicator = iMA(_Symbol,Timeframe(MaPeriod),MaParamShort+MaParamMiddle+MaParamLong,0,Ma_Mehod,TEMAPricetype);
   ArraySetAsSeries(TEMALong,true);
   
   Indicator =  iBands(_Symbol,Timeframe(BBPeriod),BBParam,0,BBDev,BBPricetype);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);



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

   if(isNotEnoughMoney())
     {
      return;
     }

   lot =SetLot(denom);




   Bid=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
   Ask=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);

   CopyBuffer(TEMAShortIndicator, 0,0,1, TEMAShort);
   CopyBuffer(TEMAMiddleIndicator, 0,0,1, TEMAMiddle);
   CopyBuffer(TEMALongIndicator, 0,0,1, TEMALong);
   
   CopyBuffer(Indicator, 1,0,2, high);
   CopyBuffer(Indicator, 2,0,2, low);

   signal = "";

   if(TEMAShort[0] > TEMAMiddle[0] && TEMAMiddle[0] > TEMALong[0])
     {
      signal= "buy";
     }
   else
      if(TEMAShort[0] < TEMAMiddle[0] && TEMAMiddle[0] < TEMALong[0])
        {
         signal= "sell";
        }




  if(EachPositionsTotal("buy") < positions/2)
     {
      if(signal =="buy")
        {
         if((high[0]*TPbuy - Ask) > 25*_Point && (Ask - low[0]*SLbuy) > SL*_Point)
           {
            trade.Buy(lot,NULL,Ask,low[0]*SLbuy,high[0]*TPbuy,NULL);
           }
        }
     }

   if(EachPositionsTotal("sell") < positions/2)
     {
      if(signal =="sell")
        {
         if((Bid - low[0]*TPsell) > 25*_Point  && (high[0]*SLsell- Bid) > SL*_Point)
           {
            trade.Sell(lot,NULL,Bid,high[0]*SLsell,low[0]*TPsell,NULL);
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
   return testingScalp();

  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
