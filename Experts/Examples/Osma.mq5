//+------------------------------------------------------------------+
//|                                     40SimpleBuyBreakevenStop.mq5 |
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
CTrade trade;
input int span1 = 5;
input int span2 = 0;
input int span3 = 0;
input int span4 = 0;
input int positions = 1;
input int TP = 10;
input int SL = 10;
input int period = 0;
input int indperiod1 = 0;
input int indperiod2 = 0;
input int SLSecondRange = 2940;
input int SLUpperLimit = 3;
input int SLTradeRange = 4;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(isNotEnoughMoney())
     {
      return;
     }
   int untradableJP[] = {5,6,7,8,9,10};
   
   if(isTooBigSpread(4))
     {
      return;
     }
   MqlDateTime dt;
   TimeToStruct(TimeCurrent()+6*3600,dt);
 
   ENUM_TIMEFRAMES period = Timeframe(period);
   ENUM_TIMEFRAMES indperiod1 = Timeframe(indperiod1);
   ENUM_TIMEFRAMES indperiod2 = Timeframe(indperiod2);
   double Bid=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
   double Ask=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);

   MqlRates PriceInfo[];
   CopyRates(_Symbol,period,0,2,PriceInfo);
   double LatestPrice = PriceInfo[1].close;
   double lot = 0.10;

   double myIOSMAArray[];
   ArraySetAsSeries(myIOSMAArray,true);
   int myIOSMADefinition = iOsMA(_Symbol,indperiod1,span1,span2,span3,PRICE_CLOSE);
   CopyBuffer(myIOSMADefinition,0,0,4,myIOSMAArray);

   double OsmaVal_1 = myIOSMAArray[0];
   double OsmaVal_2 = myIOSMAArray[1];
   double OsmaVal_3 = myIOSMAArray[2];

   string signal = "";


    
      if(OsmaVal_1 > OsmaVal_2)
        {
         signal = "buy";
        }


      if(OsmaVal_1 < OsmaVal_2)
        {
         signal = "sell";
        }

 


   if(PositionsTotal()==0 && signal=="sell")
     {
      trade.Sell(0.10,NULL,Bid,Bid+SL*_Point,Bid-TP*_Point,NULL);
     }

   if(PositionsTotal()==0 && signal=="buy")
     {
      trade.Buy(0.10,NULL,Ask,Ask-SL*_Point,Ask+TP*_Point,NULL);
     }

   Comment("The current signal is: ",signal);

  }



//+------------------------------------------------------------------+
