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
input mis_MarcosTMP timeFrame, shortTimeframe;
input int TrendPeriod, MAPeriod,DayEndHour,ExitPeriod;
ENUM_TIMEFRAMES Timeframe = defMarcoTiempo(timeFrame);
ENUM_TIMEFRAMES ShortTimeframe = defMarcoTiempo(shortTimeframe);
bool tradable = false;
double PriceToPips = PriceToPips();
double pips = ToPips();
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyTrade myTrade();
MyDate myDate();
MyPrice myPrice(PERIOD_D1, 3);
MyPrice myShortPrice(Timeframe, 3);
MyOrder myOrder(Timeframe);
CurrencyStrength CS(Timeframe, 1);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CiStochastic Sto;
CiADX ADX;
CiIchimoku Ichimoku;
CiMA MA;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   MyUtils myutils(60 * 50);
   myutils.Init();
   Ichimoku.Create(_Symbol, Timeframe, 9, 26, 52);
   MA.Create(_Symbol, Timeframe, MAPeriod, 0, MODE_EMA, PRICE_TYPICAL);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   Refresh();
   Check();

   //myPosition.CloseAllPositionsInMinute();


   myPrice.Refresh();
   MA.Refresh();
   Ichimoku.Refresh();
   myShortPrice.Refresh();

   if(MA.Main(0) - MA.Main(ExitPeriod) < 0)
      myPosition.CloseAllPositions(POSITION_TYPE_BUY);

   if(MathAbs(myPrice.At(1).close - myPrice.At(0).open) > 10) {
      if(myDate.isInTime("00:00", "10:00")) return;
   }
   if(!myTrade.isCurrentTradable || !myTrade.isTradable) return;

   int KumoResistance = Ichimoku.SenkouSpanA(1) > Ichimoku.SenkouSpanB(1) ? Ichimoku.SenkouSpanA(1) : Ichimoku.SenkouSpanB(1);


   if(MA.Main(0) - MA.Main(TrendPeriod) > 0) {
      if(Ichimoku.TenkanSen(1) > KumoResistance)
         myTrade.setSignal(ORDER_TYPE_BUY);
   }


   double PriceUnit = pips;
   if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions) {
      myTrade.Buy(myShortPrice.Lowest(0, 10), 30000);
   }
   if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions) {
      myTrade.Sell(myTrade.Bid + PriceUnit * SLCoef, myTrade.Bid - PriceUnit * TPCoef);
   }


}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer() {
   myPosition.Refresh();
   myTrade.Refresh();
   myDate.Refresh();

   if(isDayEnd() || myDate.isYearEnd() || myTrade.isLowerBalance() || myTrade.isLowerMarginLevel()) {
      myPosition.CloseAllPositions(POSITION_TYPE_BUY);
      myPosition.CloseAllPositions(POSITION_TYPE_SELL);
      myTrade.isTradable = false;
   } else {
      myTrade.isTradable = true;
   }
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
   myDate.Refresh();
   myOrder.Refresh();
   if(myDate.isMondayStart()) myTrade.isCurrentTradable = false;
   if(myOrder.wasOrderedInTheSameBar()) myTrade.isCurrentTradable = false;
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isDayEnd() {
   if((myDate.dt.hour >= DayEndHour - 1))
      return true;
   return false;
}
//+------------------------------------------------------------------+
