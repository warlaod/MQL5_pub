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
CTrade trade;
input int span1 = 14;
input int span2 = 14;
input int span3 = 14;
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
   double lot = 0.10;

   double DEMAArayL[];
   ArraySetAsSeries(DEMAArayL,true);
   CopyBuffer(iDEMA(_Symbol,period,span1,0,PRICE_CLOSE),0,0,3,DEMAArayL);
   double LDEMAVal = DEMAArayL[1];

   double DEMAArayM[];
   ArraySetAsSeries(DEMAArayM,true);
   CopyBuffer(iDEMA(_Symbol,period,span2,0,PRICE_CLOSE),0,0,3,DEMAArayM);

   double DEMAArayS[];
   ArraySetAsSeries(DEMAArayS,true);
   CopyBuffer(iDEMA(_Symbol,period,span3,0,PRICE_CLOSE),0,0,3,DEMAArayS);


   if(DEMAArayM[1] > DEMAArayS[1])
      if(DEMAArayM[2] < DEMAArayS[2])
        {
         signal="buy";
        }

   if(DEMAArayM[1] < DEMAArayS[1])
      if(DEMAArayM[2] > DEMAArayS[2])
        {
         signal="sell";
        }

   if((signal =="sell") && (PositionsTotal()< positions))
      trade.Sell(0.10,NULL,Bid,Bid+SL*_Point,Bid-TP*_Point,NULL);

   if((signal =="buy") && (PositionsTotal()< positions))
      trade.Buy(0.10,NULL,Ask,Ask-SL*_Point,Ask+TP*_Point,NULL);
  }
//+------------------------------------------------------------------+
