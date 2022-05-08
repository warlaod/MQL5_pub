//+------------------------------------------------------------------+
//|                                                  NewTemplate.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

#include <MyPkg\Trade.mqh>
#include <MyPkg\Price.mqh>
#include <Indicators\TimeSeries.mqh>
#include <Indicators\Oscilators.mqh>
#include <Indicators\Trend.mqh>
#include <Indicators\BillWilliams.mqh>
#include <Indicators\Volumes.mqh>

int eventTimer = 60; // The frequency of OnTimer
input ulong magicNumber = 21984;

Trade trade(magicNumber);
Price price(PERIOD_D1);
CiStochastic Sto;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   EventSetTimer(eventTimer);
   
   Sto.Create(_Symbol,PERIOD_D1,5,3,3,MODE_LWMA,STO_LOWHIGH);
   Sto.BufferResize(3); // How many data should be referenced and updated
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   Sto.Refresh();
   double main = Sto.Main(1);
   double nex = Sto.Main(2);
  
   
//---

}
//+------------------------------------------------------------------+
