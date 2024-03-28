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
#include <Original\MyUtils.mqh>
#include <Original\MyTrade.mqh>
#include <Original\Oyokawa.mqh>
#include <Original\MyDate.mqh>
#include <Original\MyCalculate.mqh>
#include <Original\MyTest.mqh>
#include <Original\MyPrice.mqh>
#include <Original\MyPosition.mqh>
#include <Original\MyOrder.mqh>
#include <Original\MyCHart.mqh>
#include <Original\Optimization.mqh>
#include <Indicators\TimeSeries.mqh>
#include <Indicators\Oscilators.mqh>
#include <Indicators\Trend.mqh>
#include <Indicators\BillWilliams.mqh>
#include <Indicators\Volumes.mqh>
#include <Trade\PositionInfo.mqh>

input double SLCoef, TPCoef;
input mis_MarcosTMP timeFrame;
input int PerfectPeriod, ADXPeriod;
ENUM_TIMEFRAMES Timeframe = defMarcoTiempo(timeFrame);
bool tradable = false;
double PriceToPips = PriceToPips();
double pips = PointToPips();
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyTrade myTrade();
MyDate myDate();
MyPrice myPrice(Timeframe, PerfectPeriod + 1);
MyOrder myOrder(Timeframe);
CurrencyStrength CS(Timeframe, 1);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CiMA MA10, MA20, MA50, MA100, MA200;
CiADX ADX;
int OnInit() {
   MyUtils myutils(60 * 1);
   myutils.Init();
   MA10.Create(_Symbol, Timeframe, 10, 0, MODE_EMA, PRICE_CLOSE);
   MA20.Create(_Symbol, Timeframe, 20, 0, MODE_EMA, PRICE_CLOSE);
   MA50.Create(_Symbol, Timeframe, 50, 0, MODE_EMA, PRICE_CLOSE);
   MA100.Create(_Symbol, Timeframe, 100, 0, MODE_EMA, PRICE_CLOSE);
   MA200.Create(_Symbol, Timeframe, 200, 0, MODE_EMA, PRICE_CLOSE);
   ADX.Create(_Symbol, Timeframe, 14);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   Refresh();
   Check();

   //myPosition.CloseAllPositionsInMinute();
   if(!myTrade.istradable || !tradable) return;

   MA10.Refresh();
   MA20.Refresh();
   MA50.Refresh();
   MA100.Refresh();
   MA200.Refresh();
   ADX.Refresh();
   myPrice.Refresh();


   int buyCount, sellCount = 0;

   for(int i = 0; i < PerfectPeriod; i++) {
      if((isBetween(MA10.Main(i), MA20.Main(i), MA50.Main(i)) && isBetween(MA50.Main(i), MA100.Main(i), MA200.Main(i)))) {
         if(i == PerfectPeriod - 1) break;
         buyCount++;
      } else {
         myPosition.CloseAllPositions(POSITION_TYPE_BUY);
      }
   }
   for(int i = 0; i < PerfectPeriod; i++) {
      if((isBetween(MA200.Main(i), MA100.Main(i), MA50.Main(i)) && isBetween(MA50.Main(i), MA20.Main(i), MA10.Main(i)))) {
         if(i == PerfectPeriod - 1) break;
         sellCount++;
      } else {
         myPosition.CloseAllPositions(POSITION_TYPE_SELL);
      }
   }


   if(ADX.Main(0) < 20) return;
   if(ADX.Main(0) - ADX.Main(ADXPeriod) < 0) return;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(buyCount == PerfectPeriod)
      myTrade.setSignal(ORDER_TYPE_BUY);
   if(sellCount == PerfectPeriod)
      myTrade.setSignal(ORDER_TYPE_SELL);

   double PriceUnit = pips;
   if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions / 2 ) {
      myTrade.Buy(myPrice.At(PerfectPeriod).low, myTrade.Ask + PriceUnit * TPCoef);
   }
   if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions / 2 ) {
      myTrade.Sell(myPrice.At(PerfectPeriod).high, myTrade.Bid - PriceUnit * TPCoef);
   }


}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer() {
   myPosition.Refresh();
   myTrade.Refresh();
   myOrder.Refresh();
   myDate.Refresh();


   tradable = true;


   if(myDate.isFridayEnd() || myDate.isYearEnd() || myDate.isMondayStart()) myTrade.istradable = false;
   myTrade.CheckBalance();
   myTrade.CheckMarginLevel();

   if(!myTrade.istradable) {
      myPosition.CloseAllPositions(POSITION_TYPE_BUY);
      myPosition.CloseAllPositions(POSITION_TYPE_SELL);
      tradable = false;
   }
   if(myOrder.wasOrderedInTheSameBar()) myTrade.istradable = false;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
double OnTester() {
   MyTest myTest;
   double result =  myTest.min_dd_and_mathsqrt_trades();
   return  result;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Refresh() {
   myPosition.Refresh();
   myTrade.Refresh();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Check() {
   //myTrade.CheckSpread();

}


//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
