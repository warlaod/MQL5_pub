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
CTrade trade;

input int span1 = 5;
input int span2 = 0;
input int span3 = 0;
input int span4 = 0;
input int indperiod1 = 0;
input int indperiod2 = 0;
input int TP = 40;
input int SL = 40;
input int indparam1 = 0;
input int indparam2 = 0;
input int SLSecondRange = 2940;
input int SLUpperLimit = 3;
input int SLTradeRange = 4;
input int positions = 1;
input double ps1 = 1;
input double ps2 = 1;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(isNotEnoughMoney())
     {
      return;
     }
   if(isTooBigSpread(4))
     {
      return;
     }
   MqlDateTime dt;
   TimeToStruct(TimeGMT()+6*3600,dt);
   check_summer_EU(dt.mon,dt.day,dt.hour,dt.day_of_week);
   check_summer_USA(dt.mon,dt.day,dt.hour,dt.day_of_week);
     
   ENUM_TIMEFRAMES indperiod1 = Timeframe(indperiod1);
   ENUM_TIMEFRAMES indperiod2 = Timeframe(indperiod2);
   double Bid=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
   double Ask=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
   string signal = "";
   MqlRates PriceInfo[];
   ArraySetAsSeries(PriceInfo,true);
   CopyRates(_Symbol,_Period,0,2,PriceInfo);
   double LatestPrice = PriceInfo[1].close;
   double lot = 0.40;
   
   double Bulls[];
   ArraySetAsSeries(Bulls,true);
   CopyBuffer(iBullsPower(_Symbol,indperiod1,indparam1),0,0,3,Bulls);
   
   double Bears[];
   ArraySetAsSeries(Bears,true);
   CopyBuffer(iBearsPower(_Symbol,indperiod1,indparam1),0,0,3,Bears);


   if(MathAbs(Bulls[0]) - MathAbs(Bears[0])*ps1 > 0 && Bulls[0] > 0 && MathAbs(Bulls[0]) > ps2){
      signal = "buy";
      CloseAllSellPositions();
   }
    if(MathAbs(Bears[0]) - MathAbs(Bulls[0])*ps1 > 0 && Bears[0] < 0 && MathAbs(Bears[0]) > ps2){
      signal = "sell";
      CloseAllBuyPositions();
   }


   if((signal =="sell") && (PositionsTotal()< positions))
      trade.Sell(lot,NULL,Bid,Bid+SL*_Point,Bid-TP*_Point,NULL);

   if((signal =="buy") && (PositionsTotal()< positions))
      trade.Buy(lot,NULL,Ask,Ask-SL*_Point,Ask+TP*_Point,NULL);
  }
//+------------------------------------------------------------------+
