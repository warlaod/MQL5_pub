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
   ENUM_TIMEFRAMES period = Timeframe(tf);
   double Bid=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
   double Ask=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
   string signal = "";
   MqlRates PriceInfo[];
   CopyRates(_Symbol,_Period,0,3,PriceInfo);
   double LatestPrice = PriceInfo[1].close;
   double lot = 0.10;

   double jaw[],teeth[],lips[];
   ArraySetAsSeries(jaw,true);
   ArraySetAsSeries(teeth,true);
   ArraySetAsSeries(lips,true);
   double alligator=iAlligator(_Symbol,_Period,13,8,8,5,5,3,MODE_SMMA,PRICE_MEDIAN);
   CopyBuffer(alligator,0,0,6,jaw);
   CopyBuffer(alligator,1,0,6,teeth);
   CopyBuffer(alligator,2,0,6,lips);

   if(LatestPrice > lips[0] && lips[0] > teeth[0] && teeth[0] > jaw[0])
     {
      if(jaw[0] > jaw[5])
        {
         signal ="buy";
        }
      else
        {
         signal = "sell";
        }
     }
   if(LatestPrice < lips[0] && lips[0] < teeth[0] && teeth[0] < jaw[0])
     {
      if(jaw[0] < jaw[5])
        {
         signal = "sell";
        }
      else
        {
         signal = "buy";
        }

     }


   if((signal =="sell") && (PositionsTotal()< positions))
      trade.Sell(0.10,NULL,Bid,Bid+SL*_Point,Bid-TP*_Point,NULL);

   if((signal =="buy") && (PositionsTotal()< positions))
      trade.Buy(0.10,NULL,Ask,Ask-SL*_Point,Ask+TP*_Point,NULL);


   Comment(
      "JAW:",jaw[0],"\n",
      "TEETH:",teeth[0],"\n",
      "LIPS:",lips[0],"\n"
   );

  }
//+------------------------------------------------------------------+
