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
CTrade trade;

double lot = 0.10;
MqlDateTime dt;

/*
int EmaIndicator
input int EmaPeriod,EmaPriceType;
double Ema[];
*/

input ENUM_TIMEFRAMES MacdShortTimeframe,MacdLongTimeframe;
input ENUM_APPLIED_PRICE MacdAppliedPrice;
input double TPCoef,SLCoef;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CiMACD ciMACDShort;
CiMACD ciMACDLong;
CiATR ciATR;
MyTrade myTrade(0.1,true);
int OnInit()
  {
   MyUtils myutils(12602,0);
   myutils.Init();
   
   ciMACDShort.Create(_Symbol,MacdShortTimeframe,12,26,9,MacdAppliedPrice);
   ciMACDLong.Create(_Symbol,MacdLongTimeframe,12,26,9,MacdAppliedPrice);
   ciATR.Create(_Symbol,MacdShortTimeframe,14);
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
   
   ciMACDLong.Refresh();
   ciMACDShort.Refresh();
   ciATR.Refresh();
   
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
   
   double currentATR =ciATR.Main(0);
   if(EachPositionsTotal("buy") < positions/2 && myTrade.signal=="buy")
     {
      trade.Buy(lot,NULL,myTrade.Ask,myTrade.Ask-currentATR*SLCoef,myTrade.Ask+currentATR*TPCoef,NULL);
     }

   if(EachPositionsTotal("sell") < positions/2 && myTrade.signal=="sell")
     {
      trade.Sell(lot,NULL,myTrade.Bid,myTrade.Bid+currentATR*SLCoef,myTrade.Bid-currentATR*TPCoef,NULL);
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
