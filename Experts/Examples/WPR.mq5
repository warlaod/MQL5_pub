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
input int span1 = 5;
input int span2 = 0;
input int span3 = 0;
input int span4 = 0;
input int period = 0;
input int indperiod1 = 0;
input int indperiod2 = 0;
input int TP = 10;
input int SL = 10;
input int indparam1 = 80;
input int indparam2 = 20;
input int SLSecondRange = 2940;
input int SLUpperLimit = 8;
input int SLTradeRange = 10;
input int positions = 1;
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
   ENUM_TIMEFRAMES period = Timeframe(period);
   ENUM_TIMEFRAMES indperiod1 = Timeframe(indperiod1);
   ENUM_TIMEFRAMES indperiod2 = Timeframe(indperiod2);
   double Bid=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
   double Ask=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
   string signal = "";
   MqlRates PriceInfo[];
   CopyRates(_Symbol,period,0,2,PriceInfo);
   double LatestPrice = PriceInfo[1].close;
   double lot = 0.10;



   double WPRArray[];
   ArraySetAsSeries(WPRArray,true);
   int WPRDefinition = iWPR(_Symbol,indperiod1,span1);
   CopyBuffer(WPRDefinition,0,0,3,WPRArray);
   double WPRValue = NormalizeDouble(WPRArray[0],2);
   double LastWPRValue = NormalizeDouble(WPRArray[1],2);
   
   
   if(WPRValue > LastWPRValue+indparam1 && LastWPRValue < -80)
     {
      signal = "buy";
     }

   if(WPRValue < LastWPRValue-indparam1 && LastWPRValue > -20)
     {
      signal = "sell";
     }
     



   if((signal =="sell") && (PositionsTotal()< positions))
      trade.Sell(lot,NULL,Bid,Bid+SL*_Point,Bid-TP*_Point,NULL);

   if((signal =="buy") && (PositionsTotal()< positions))
      trade.Buy(lot,NULL,Ask,Ask-SL*_Point,Ask+TP*_Point,NULL);



  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
