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
#include <Ramune\OptimizedParameter.mqh>
#include <Ramune\Optimization.mqh>
#include <Ramune\Trade\Trade.mqh>
#include <Ramune\Trade\VolumeByMargin.mqh>
#include <Ramune\Price.mqh>

#include <Ramune\Position\PositionStore.mqh>
#include <Ramune\Position\Position.mqh>
#include <Ramune\Time.mqh>
#include <Ramune\Trailing\Appointed.mqh>
#include <Ramune\OrderHistory.mqh>
#include <Indicators\TimeSeries.mqh>
#include <Indicators\Oscilators.mqh>
#include <Indicators\Trend.mqh>
#include <Indicators\BillWilliams.mqh>
#include <Indicators\Volumes.mqh>

int eventTimer = 60; // The frequency of OnTimer
input ulong magicNumber = 21984;
input int equityThereShold = 1500;
input double risk = 5;
input int pricePeriod;
input int spreadLimit = 999;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Trade trade(magicNumber);
Price price(PERIOD_MN1);
Time time;
OrderHistory orderHistory(magicNumber);

input double tpCoef, rangeCoef;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   EventSetTimer(eventTimer);

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double requiredMargin1, requiredMargin2;
input string symbol1, symbol2;

PositionStore psSymbol1(magicNumber, symbol1);
PositionStore psSymbol2(magicNumber, symbol2);

CiFractals frac;


void OnTick() {
   if(!CheckMarketOpen() || !CheckEquityThereShold(equityThereShold)) return;

   



}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double OnTester() {
   Optimization optimization;
   return optimization.ViceVersa();
}