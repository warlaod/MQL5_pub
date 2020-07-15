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
#include <Original\caluculate.mqh>
#include <Original\MyUtils.mqh>
#include <Original\MyTrade.mqh>
#include <Original\MyCalculate.mqh>
#include <Original\MyTest.mqh>
#include <Indicators\TimeSeries.mqh>
#include <Indicators\Oscilators.mqh>
#include <Trade\OrderInfo.mqh>
CiMACD ciMACDShort;
CiMACD ciMACDLong;
MyTrade myTrade(0.1);
CTrade trade;

string myTrade.signal;
input int positions;
double lot = 0.10;
MqlDateTime dt;

/*
int EmaIndicator
input int EmaPeriod,EmaPriceType;
double Ema[];
*/

int MacdShortIndicator,MacdLongIndicator,ATRIndicator;
input ENUM_TIMEFRAMES MacdShortTimeframe,MacdLongTimeframe;
input ENUM_APPLIED_PRICE MacdAppliedPrice;
input double TPCoef,SLCoef;
double LongMacd[],LongMacdmyTrade.signal[],ShortMacd[],ShortMacdmyTrade.signal[],ATR[];
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   MyUtils myutils(12602,0);
   myutils.Init();
   
   ciMACDShort.Create(_Symbol,MacdShortTimeframe,12,26,9,MacdAppliedPrice);
   ciMACDLong.Create(_Symbol,MacdLongTimeframe,12,26,9,MacdAppliedPrice);
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
    myTrade.istradable = true;
   if(isNotEnoughMoney()){
       myTrade.istradable = false;
   }
   myTrade.CheckSpread();
   if(!myTrade.istradable) {
      return;
   }
   
   Ask = myTrade.Ask();
   Bid = myTrade.Bid();
   
   ciMACDLong.Refresh();
   ciMACDShort.Refresh();
   
   myTrade.signal = "";

   double LongHistogram[2];
   double ShortHistogram[2];
   for(int i=0; i<2; i++)
     {
      LongHistogram[i] = LongMacd[i] - LongMacdmyTrade.signal[i];
      ShortHistogram[i] = ShortMacd[i] - ShortMacdmyTrade.signal[i];
     }


   if(isUntradable())
     {
      return;
     }
   
   myTrade.signal = "";
   if(LongHistogram[0] > 0 &&ciMACDLong.Main(0) > 0)
     {
      myTrade.signal ="buybuy";
     }
   else
      if(LongHistogram[0] < 0 &&ciMACDLong.Main(0) < 0)
        {
         myTrade.signal ="sellsell";
        }

   if(ShortHistogram[1] < 0 && ShortHistogram[0] > 0 && ciMACDShort.Main(0) < 0 && myTrade.signal == "buybuy")
     {
      myTrade.signal = "buy";
     }
   else
      if(ShortHistogram[1] > 0 && ShortHistogram[0] < 0 && ciMACDShort.Main(0) > 0 && myTrade.signal == "sellsell")
        {
         myTrade.signal = "sell";
        }

   if(EachPositionsTotal("buy") < positions/2 && myTrade.signal=="buy")
     {
      trade.Buy(lot,NULL,Ask,Ask-ATR[0]*SLCoef,Ask+ATR[0]*TPCoef,NULL);
     }

   if(EachPositionsTotal("sell") < positions/2 && myTrade.signal=="sell")
     {
      trade.Sell(lot,NULL,Bid,Bid+ATR[0]*SLCoef,Bid-ATR[0]*TPCoef,NULL);
     }


  }
//+------------------------------------------------------------------+
double OnTester()
  {

   if(!setVariables())
     {
      return -99999999;
     }
   return testingScalpMoreTrade();

  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isUntradable()
  {
   TimeToStruct(TimeCurrent(),dt);
   if(dt.day_of_week == FRIDAY)
     {
      if((dt.hour == 22 && dt.min > 0) || dt.hour == 23)
        {
         CloseAllBuyPositions();
         CloseAllSellPositions();
         return true;
        }
     }
   
   if(isYearEnd(dt.mon,dt.day)){
      return true;
   }
   if(isNotEnoughMoney())
     {
      return true;
     }
   return false;

  }
//+------------------------------------------------------------------+
