//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
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
input int MIN;
input int denom;
input int positions;
double lot = 0.10;
MqlDateTime dt;

bool tradable = true;
int EMAIndicator;
input int EMAPeriod,EMAPriceType,EMARange;
input double EMATrendCri;
double EMA[];

int ATRIndicator;
input double TPCoef,SLCoef;
double ATR[];

int RSIIndicator;
double RSI[];
input int RSICri;

input int spread;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   EventSetTimer(1800);
   EMAIndicator = iMA(_Symbol,Timeframe(EMAPeriod),10,0,MODE_EMA,PRICE_CLOSE);
   RSIIndicator = iRSI(_Symbol,Timeframe(EMAPeriod),14,PRICE_CLOSE);
   ATRIndicator = iATR(_Symbol,Timeframe(EMAPeriod),14);

   ArraySetAsSeries(RSI,true);
   ArraySetAsSeries(EMA,true);
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(isTooBigSpread(spread) && tradable == false)
     {
      return;
     }
//
   double Bid=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
   double Ask=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
   signal = "";
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   CopyBuffer(EMAIndicator,0,0,EMARange,EMA);
   CopyBuffer(RSIIndicator,0,0,1,RSI);
   CopyBuffer(ATRIndicator,0,0,1,ATR);

   double EMATrend = MathAbs(EMA[0]-EMA[EMARange-1]);

   if(EMATrend  < EMATrendCri*_Point && RSI[0] > RSICri && RSI[0] < 100 - RSICri)
     {
      if(Bid > EMA[0])
        {
         signal = "sell";
        }
      else
        {
         signal = "buy";
        }
     }
   if(PositionsTotal() < positions/2)
     {
      if(signal=="buy")
        {
         trade.Buy(lot,NULL,Ask,Ask-ATR[0]*SLCoef,Ask+ATR[0]*TPCoef,NULL);
        }
      else
         if(signal=="sell")
           {
            trade.Sell(lot,NULL,Bid,Bid+ATR[0]*SLCoef,Bid-ATR[0]*TPCoef,NULL);
           }
     }


  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer()
  {
   tradable  = true;
   //lot =SetLot(denom);
   if(isNotEnoughMoney())
     {
      tradable = false;
      return;
     }
   TimeToStruct(TimeCurrent(),dt);
   if(dt.day_of_week == FRIDAY)
     {
      if((dt.hour == 22 && dt.min > 0) || dt.hour == 23)
        {
         CloseAllBuyPositions();
         CloseAllSellPositions();
         tradable = false;
         return;
        }
     }
   if(isYearEnd(dt.mon,dt.day))
     {
      tradable = false;
      return;
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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
