//+------------------------------------------------------------------+
//|                                                    1003iosma.mq5 |
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
input int ADXLine = 20;
input int span1 = 5;
input int span2 = 3;
input int span3 = 3;
input int span4 = 14;
input int positions = 1;
input int TP = 10;
input int SL = 10;
input int period = 2;
input int indperiod1 = 0;
input int indperiod2 = 0;
input int SLSecondRange = 2940;
input int SLUpperLimit = 3;
input int SLTradeRange = 4;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+



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
   int hours[] = {1,2,3,4,5};
   ENUM_TIMEFRAMES period = Timeframe(period);
   ENUM_TIMEFRAMES indperiod1 = Timeframe(indperiod1);
   ENUM_TIMEFRAMES indperiod2 = Timeframe(indperiod1);
   double Bid=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
   double Ask=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
   string signal = "";
   MqlRates PriceInfo[];
   CopyRates(_Symbol,period,0,3,PriceInfo);
   double LatestPrice = PriceInfo[1].close;
   double lot = 0.10;


   double MAArray[];
   ArraySetAsSeries(MAArray,true);
   CopyBuffer(iMA(_Symbol,indperiod1,span1,0,MODE_EMA,PRICE_CLOSE),0,0,3,MAArray);

   double plusDI[],minusDI[];
   int ADX = iADX(_Symbol, indperiod2, span2);
   CopyBuffer(ADX,1,0,3,plusDI);
   CopyBuffer(ADX,2,0,3,minusDI);
   ArraySetAsSeries(plusDI,true);
   ArraySetAsSeries(minusDI,true);
   double plusDIVal = NormalizeDouble(plusDI[0],2);
   double plusDIValpre = NormalizeDouble(plusDI[1],2);
   double minusDIVal = NormalizeDouble(minusDI[0],2);
   double minusDIValpre = NormalizeDouble(minusDI[1],2);

   if(plusDIVal > ADXLine && plusDIValpre < ADXLine)
     {
      signal = "buy";
     }

   if(minusDIVal > ADXLine && minusDIValpre < ADXLine)
     {
      signal = "sell";
     }

   if(StopLossCount(SLTradeRange,SLSecondRange) >= SLUpperLimit)
     {
      signal = "";
     }

   if(PositionsTotal()< positions && signal=="sell")
     {
      trade.Sell(lot,NULL,Bid,Bid+SL*_Point,Bid-TP*_Point,NULL);
     }

   if(PositionsTotal()< positions && signal=="buy")
     {
      trade.Buy(lot,NULL,Ask,Ask-SL*_Point,Ask+TP*_Point,NULL);
     }



  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
