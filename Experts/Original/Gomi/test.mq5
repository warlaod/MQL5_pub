//+------------------------------------------------------------------+
//|                                                         test.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#include <Indicators\TimeSeries.mqh>
#include <Original\MyUtils.mqh>
CiHigh High;
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   High.Create(_Symbol,PERIOD_CURRENT);
  
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   High.Refresh();
   int array;
   double high = High.MaxIndex(0,10);
   double fes = High.MaxValue(0,10,array);
   int aa =1 ;
  }
//+------------------------------------------------------------------+

