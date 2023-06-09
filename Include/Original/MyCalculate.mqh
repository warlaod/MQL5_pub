//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#include <Generic\Interfaces\IComparable.mqh>
#include <Indicators\TimeSeries.mqh>
#include <Indicators\Oscilators.mqh>
#include <Indicators\Trend.mqh>
#include <Indicators\BillWilliams.mqh>
#include <Indicators\Volumes.mqh>
#include <Arrays\ArrayDouble.mqh>
#include <Original\MyPrice.mqh>

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isBetween(double top, double middle, double bottom) {
   if(top - bottom > 0 && top - middle > 0 && middle - bottom > 0) return true;
   return false;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isDeadCross(double old_main, double old_signal, double new_main, double new_signal) {
   if(old_main > old_signal && new_main < new_signal) return true;
   return false;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isGoldenCross(CIndicator &Indicator, int crossPoint = 0, int mainBuffer = 0, int signalBuffer = 1) {
   if(Indicator.GetData(mainBuffer, crossPoint + 1) < Indicator.GetData(signalBuffer, crossPoint + 1)) {
      if(Indicator.GetData(mainBuffer, crossPoint) > Indicator.GetData(signalBuffer, crossPoint)) return true;
   }
   return false;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isGoldenCross(double old_main, double old_signal, double new_main, double new_signal) {
   if(old_main < old_signal && new_main > new_signal) return true;
   return false;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isDeadCross(CIndicator &Indicator, int crossPoint = 0, int mainBuffer = 0, int signalBuffer = 1) {
   if(Indicator.GetData(mainBuffer, crossPoint + 1) > Indicator.GetData(signalBuffer, crossPoint + 1)) {
      if(Indicator.GetData(mainBuffer, crossPoint) < Indicator.GetData(signalBuffer, crossPoint)) return true;
   }
   return false;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isTurnedToRise(CIndicator &Indicator, int crossPoint = 0) {
   if(Indicator.GetData(0, crossPoint + 1) < 0 && Indicator.GetData(0, crossPoint) > 0) return true;
   return false;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isTurnedToDown(CIndicator &Indicator, int crossPoint = 0) {
   if(Indicator.GetData(0, crossPoint + 1) > 0 && Indicator.GetData(0, crossPoint) < 0) return true;
   return false;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isTurnedToRise(double old_main, double new_main) {
   if(old_main < 0 && new_main > 0) return true;
   return false;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isTurnedToDown(double old_main, double new_main) {
   if(old_main > 0 && new_main < 0) return true;
   return false;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isAllAbove(CIndicator &Indicator, double criterion, int period, int start = 0) {
   for(int i = start; i < period; i++) {
      if(Indicator.GetData(0, i) <= criterion) return false;
   }
   return true;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isAllUnder(CIndicator &Indicator, double criterion, int period, int start = 0) {
   for(int i = start; i < period; i++) {
      if(Indicator.GetData(0, i) >= criterion) return false;
   }
   return true;
}

bool isRising(CIndicator &Indicator, int start = 0, int period = 1, int BufferNum = 0) {
   for(int i = start; i < start+period; i++) {
      if(Indicator.GetData(BufferNum, i) < Indicator.GetData(BufferNum,i+1)) return false;
   }
   return true;
}

bool isFalling(CIndicator &Indicator, int start = 0, int period = 1, int BufferNum = 0) {
   for(int i = start; i < start+period; i++) {
      if(Indicator.GetData(BufferNum, i) > Indicator.GetData(BufferNum,i+1)) return false;
   }
   return true;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isAbsUnder(double AbsVal, double UnderLine) {
   if(MathAbs(AbsVal) < UnderLine) return true;
   return false;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double NewBarsCount(datetime LastTime, ENUM_TIMEFRAMES Timeframe) {
   return Bars(_Symbol, Timeframe, Timeframe, TimeCurrent());
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
