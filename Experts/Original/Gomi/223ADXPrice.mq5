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
#include <Original\Optimization.mqh>
#include <Original\MyOrder.mqh>
#include <Indicators\TimeSeries.mqh>
#include <Indicators\Oscilators.mqh>
#include <Indicators\Trend.mqh>
#include <Indicators\BillWilliams.mqh>
#include <Indicators\Volumes.mqh>

input double SLCoef, TPCoef;
input mis_MarcosTMP timeFrame;
ENUM_TIMEFRAMES Timeframe = defMarcoTiempo(timeFrame);
input int ADXPeriod, MAPeriod, LosscutRange;
bool tradable = false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyTrade myTrade();
MyDate myDate();
MyPrice myPrice(Timeframe, 3);
MyOrder myOrder(Timeframe);
CurrencyStrength CS(Timeframe, 1);


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CiADX ADX;
CiMA MA, MALong;
CiATR ATR;
int OnInit() {
   MyUtils myutils(60 * 1);
   myutils.Init();

   ADX.Create(_Symbol, Timeframe, ADXPeriod);
   MA.Create(_Symbol, Timeframe, MAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   MALong.Create(_Symbol, Timeframe, MAPeriod * 5, 0, MODE_EMA, PRICE_CLOSE);
   ATR.Create(_Symbol, Timeframe, 14);

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

   MA.Refresh();
   ADX.Refresh();
   myPrice.Refresh();
   ATR.Refresh();
   MALong.Refresh();

   if(isBetween(MALong.Main(0),MA.Main(0),myPrice.At(0).close)) {
      if(isGoldenCross(ADX.Plus(2), ADX.Minus(2), ADX.Plus(1), ADX.Minus(1)))
         myTrade.setSignal(ORDER_TYPE_BUY);
   }

   if(isBetween(myPrice.At(0).close,MA.Main(0),MALong.Main(0))) {
      if(isGoldenCross(ADX.Minus(2), ADX.Plus(2), ADX.Minus(1), ADX.Plus(1)))
         myTrade.setSignal(ORDER_TYPE_SELL);
   }

   double PriceUnit = ATR.Main(0);
   if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions / 2 ) {
      myTrade.Buy(myPrice.Lowest(0, LosscutRange) - PriceUnit * SLCoef, MALong.Main(0));
   }
   if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions / 2 ) {
      myTrade.Sell(myPrice.Highest(0, LosscutRange) + PriceUnit * SLCoef,MALong.Main(0));
   }


}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer() {
   myPosition.Refresh();
   myTrade.Refresh();
   myDate.Refresh();
   myOrder.Refresh();

   tradable = true;

   //if(!myDate.isInTime("01:00", "07:00")) myTrade.istradable = false;
   if(myOrder.wasOrderedInTheSameBar()) myTrade.istradable = false;

   if(myDate.isFridayEnd() || myDate.isYearEnd()) myTrade.istradable = false;
   myTrade.CheckBalance();
   myTrade.CheckMarginLevel();

   if(!myTrade.istradable) {
      myPosition.CloseAllPositions(POSITION_TYPE_BUY);
      myPosition.CloseAllPositions(POSITION_TYPE_SELL);
      tradable = false;
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
double OnTester() {
   MyTest myTest;
   double result =  myTest.min_dd_and_mathsqrt_profit_trades();
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
