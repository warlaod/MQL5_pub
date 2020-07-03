//+------------------------------------------------------------------+
//|                                            1009ScalpFractals.mq5 |
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
#include <Original\Ontester.mqh>
CTrade trade;

string signal;
input int SL;
input int MIN;
input int denom;
input int positions;
double lot = 0.10;
MqlDateTime dt;

int EMAShortIndicator,EMAMiddleIndicator,EMALongIndicator;
input int EMAPeriod,EMAPriceType;
input int TrendCri;
double EMAShort[],EMAMiddle[],EMALong[];
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   EMAShortIndicator = iMA(_Symbol,Timeframe(EMAPeriod),5,0,MODE_EMA,EMAPriceType);
   EMAMiddleIndicator = iMA(_Symbol,Timeframe(EMAPeriod),20,0,MODE_EMA,EMAPriceType);
    EMALongIndicator = iMA(_Symbol,Timeframe(EMAPeriod),40,0,MODE_EMA,EMAPriceType);
   
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(isUntradable()){
      return;
      }
   lot =SetLot(denom);
   double Bid=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
   double Ask=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
   signal = "";
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   CopyBuffer(EMAShortIndicator,0,0,2,EMAShort);
   CopyBuffer(EMAMiddleIndicator,0,0,2,EMAMiddle);
   CopyBuffer(EMALongIndicator,0,0,2,EMALong);
   
   double EMATrend = EMAShort[0]-EMAShort[1];
   if(EMAShort[0] > EMAMiddle[0] && EMAMiddle[0] > EMALong[0] && EMATrend > TrendCri*_Point){
      signal = "buy";
   }
   
   if(EMAShort[0] < EMAMiddle[0] && EMAMiddle[0] < EMALong[0]  && EMATrend > -TrendCri*_Point){
      signal = "sell";
   }
   
   double TPline = MathAbs(EMAShort[0] - EMAMiddle[0]);
   if(EachPositionsTotal("buy") < positions/2 && signal=="buy")
     {
      if(isNotInvalidTrade(EMAMiddle[0],Ask+TPline,Ask,true))
        {
         trade.Buy(lot,NULL,Ask,EMAMiddle[0],Ask+TPline,NULL);
        }
     }

   if(EachPositionsTotal("sell") < positions/2 && signal=="sell")
     {
      if(isNotInvalidTrade(EMAMiddle[0],Bid-TPline,Bid,false))
        {
         trade.Sell(lot,NULL,Bid,EMAMiddle[0],Bid-TPline,NULL);
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

bool isUntradable(){
   TimeToStruct(TimeCurrent(),dt);
   if(dt.day_of_week == FRIDAY)
     {
      if((dt.hour == 22 && dt.min > MIN) || dt.hour == 23)
        {
         CloseAllBuyPositions();
         CloseAllSellPositions();
         return true;
        }
     }

   if(isTooBigSpread(2))
     {
      return true;
     }
   if(isNotEnoughMoney())
     {
      return true;
     }
   return false;
   
}