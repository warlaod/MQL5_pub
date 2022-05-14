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

#include <MyPkg\Trade\Trade.mqh>
#include <MyPkg\Price.mqh>
#include <MyPkg\Position\PositionStore.mqh>
#include <Indicators\TimeSeries.mqh>
#include <Indicators\Oscilators.mqh>
#include <Indicators\Trend.mqh>
#include <Indicators\BillWilliams.mqh>
#include <Indicators\Volumes.mqh>

int eventTimer = 60; // The frequency of OnTimer
input ulong magicNumber = 21984;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Trade trade(magicNumber);
Price price(PERIOD_D1);
CiAlligator Allig;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   EventSetTimer(eventTimer);

   Allig.Create(_Symbol, PERIOD_H1, 13, 8, 8, 5, 5, 3, MODE_LWMA, PRICE_CLOSE);
   Allig.BufferResize(3); // How many data should be referenced and updated

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   if(!CheckMarketOpen()) {
      return;
   }
   Allig.Refresh();

   double ask = Ask();
   double bid = Bid();
   tradeRequest tR1 = {magicNumber,PERIOD_D1, 0.1, ORDER_TYPE_BUY, ask, ask - 100 * _Point, ask + 100 * _Point};
   trade.PositionOpen(tR1);
   tradeRequest tR2 = {magicNumber,PERIOD_D1, 0.1, ORDER_TYPE_SELL, bid, bid + 100 * _Point, bid - 100 * _Point};
   trade.PositionOpen(tR2);

   double one = Allig.Lips(-1);
   double two = Allig.Lips(-2);
   double three = Allig.Lips(-3);


   PositionStore pS(magicNumber);





//---

}
//+------------------------------------------------------------------+
