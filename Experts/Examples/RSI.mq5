//+------------------------------------------------------------------+
//|                                              15SimpleBuyStop.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
#include <Original\prices.mqh>
#include <Original\positions.mqh>
#include <Original\period.mqh>
CTrade trade;
input int testspsn = 14;
input int positions = 1;
input int TP = 10;
input int SL = 10;
input int tf = 0;



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   int untradableJP[] = {4,5,6,7,8};
   if(isTooBigSpread(4))
     {
      return;
     }
   MqlDateTime dt;
   TimeToStruct(TimeLocal(),dt);
   if(!isTradableJP(untradableJP,dt.hour))
     {
      return;
     }
   check_summer_EU(dt.mon,dt.day,dt.hour,dt.day_of_week);
   check_summer_USA(dt.mon,dt.day,dt.hour,dt.day_of_week);
   ENUM_TIMEFRAMES period = Timeframe(tf);
   double Bid=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
   double Ask=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
   string signal = "";
   MqlRates PriceInfo[];
   CopyRates(_Symbol,_Period,0,3,PriceInfo);
   double LatestPrice = PriceInfo[1].close;


   double plusDI[],minusDI[];
   int ADX = iADX(_Symbol, period, 14);
   CopyBuffer(ADX,1,0,2,plusDI);
   CopyBuffer(ADX,2,0,2,minusDI);
   ArraySetAsSeries(plusDI,true);
   ArraySetAsSeries(minusDI,true);
   double plusDIVal = NormalizeDouble(plusDI[0],2);
   double minusDIVal = NormalizeDouble(minusDI[0],2);


   double myRSIArray[];
   ArraySetAsSeries(myRSIArray,true);
   int myRSIDefinition =iRSI(_Symbol,period,testspsn,PRICE_CLOSE);
   CopyBuffer(myRSIDefinition,0,0,1,myRSIArray);
   double myRSIValue = NormalizeDouble(myRSIArray[0],2);

   if(myRSIValue < 30)
     {
      signal="buy";

     }

   if(myRSIValue > 70)
     {
      signal="sell";
     }


   if((signal =="sell") && (PositionsTotal()< positions))
      trade.Sell(0.10,NULL,Bid,Bid+10*_Point,Bid-TP*_Point,NULL);

   if((signal =="buy") && (PositionsTotal()< positions))
      trade.Buy(0.10,NULL,Ask,Ask-10*_Point,Ask+TP*_Point,NULL);


  }
//+------------------------------------------------------------------+
