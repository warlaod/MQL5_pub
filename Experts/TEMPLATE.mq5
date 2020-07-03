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
input double TPbuy,SLbuy,TPsell,SLsell;
double lot = 0.10;
MqlDateTime dt;
MqlRates price;

int SarIndicator;
double Sar[];
input int SarPeriod;
input double SarStep,SarMaximum;

int StdIndicator;
double Std[];
input int Std_Ma_Mehod,StdPeriod,StdParam,StdPriceType;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   ArraySetAsSeries(price.true);
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
   
   if(Sar[1] > Ask && Ask > Sar[0])
        {
         signal="buy";
        }
      else
         if(Sar[1] < Bid && Bid < Sar[0])
           {
            signal = "sell";
           }

   if(EachPositionsTotal("buy") < positions/2 && signal=="buy")
     {
      if(UpDif*TPCoefLong > 25*_Point && UpDif*SLCoefLong > SL*_Point)
        {
         trade.Buy(lot,NULL,Ask,Ask-250*_Point,Ask+50*_Point,NULL);
        }
     }

   if(EachPositionsTotal("sell") < positions/2 && signal=="sell")
     {
      if(Bid+LowDif*SLCoefShort > 25*_Point  && Bid-LowDif*TPCoefShort > SL*_Point)
        {
         trade.Sell(lot,NULL,Bid,Bid+LowDif*TPCoefShort,Bid-LowDif*SLCoefShort,NULL);
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