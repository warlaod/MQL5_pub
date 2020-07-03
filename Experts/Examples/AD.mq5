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
   
   MqlDateTime dt;
   TimeToStruct(TimeLocal(),dt);
   check_summer_EU(dt.mon,dt.day,dt.hour,dt.day_of_week);
   check_summer_USA(dt.mon,dt.day,dt.hour,dt.day_of_week);
   int hours1[] = {0,2,5};
   bool summer = isTradableEU(hours1,dt.hour);
   int hours[][2] ={{0,0},{22,30}};
   bool houar = PreviousCloseHour(hours,summer_USA,dt.hour,dt.min);
   ENUM_TIMEFRAMES period = Timeframe(tf);
   double Bid=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
   double Ask=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
   string signal = "";
   MqlRates PriceInfo[];
   CopyRates(_Symbol,_Period,0,3,PriceInfo);
   double LatestPrice = PriceInfo[1].close;
   double lot = 0.10;


   double myPriceArray[];
   double myMovingAverageArray[];
   ArraySetAsSeries(myPriceArray,true);
   ArraySetAsSeries(myMovingAverageArray,true);
   CopyBuffer(iMA(_Symbol,_Period,testspsn,0,MODE_SMA,PRICE_CLOSE),0,0,6,myMovingAverageArray);

   double MovingAVR = myMovingAverageArray[0];
   double LastMovingAVR = myMovingAverageArray[5];
   CopyBuffer(iAD(_Symbol,_Period,VOLUME_TICK),0,0,6,myPriceArray);

   double IADValue = myPriceArray[0];
   double LastIADValue = myPriceArray[5];

   if(MovingAVR > LastMovingAVR)
     {
      if(IADValue > LastIADValue)
        {
         signal = "buy";
        }
      else
        {
         signal = "sell";
        }
     }

   if(MovingAVR < LastMovingAVR)
     {
      if(IADValue < LastIADValue)
        {
         signal ="sell";
        }
      else
        {
         signal="buy";
        }
     }

   if((signal =="sell") && (PositionsTotal()< positions))
      trade.Sell(0.10,NULL,Bid,Bid+SL*_Point,Bid-TP*_Point,NULL);

   if((signal =="buy") && (PositionsTotal()< positions))
      trade.Buy(0.10,NULL,Ask,Ask-SL*_Point,Ask+TP*_Point,NULL);
  }
//+------------------------------------------------------------------+
