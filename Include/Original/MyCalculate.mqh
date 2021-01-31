//+------------------------------------------------------------------+
//|                                                  MyCalculate.mqh |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#include <Generic\Interfaces\IComparable.mqh>
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
// #define MacrosHello   "Hello, world!"
// #define MacrosYear    2010
//+------------------------------------------------------------------+
//| DLL imports                                                      |
//+------------------------------------------------------------------+
// #import "user32.dll"
//   int      SendMessageA(int hWnd,int Msg,int wParam,int lParam);
// #import "my_expert.dll"
//   int      ExpertRecalculate(int wParam,int lParam);
// #import
//+------------------------------------------------------------------+
//| EX5 imports                                                      |
//+------------------------------------------------------------------+
// #import "stdlib.ex5"
//   string ErrorDescription(int error_code);
// #import
//+------------------------------------------------------------------+


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
bool isGoldenCross(double old_main, double old_signal, double new_main, double new_signal) {
   if(old_main < old_signal && new_main > new_signal) return true;
   return false;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
template<typename T> bool isTurnedToRise(T old_main, T new_main) {
   if(old_main < 0 && new_main > 0) return true;
   return false;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
template<typename T> bool isTurnedToDown(T old_main, T new_main) {
   if(old_main > 0 && new_main < 0) return true;
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
double PriceToPips() {
   double pips = 0;

   // 現在の通貨ペアの小数点以下の桁数を取得
   int digits = _Digits;

   // 3桁・5桁のFXブローカーの場合
   if(digits == 3 || digits == 5) {
      pips = MathPow(10, digits) / 10;
   }
   // 2桁・4桁のFXブローカーの場合
   if(digits == 2 || digits == 4) {
      pips = MathPow(10, digits);
   }
   // 少数点以下を１桁に丸める（目的によって桁数は変更する）
   pips = NormalizeDouble(pips, 1);

   return(pips);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double PointToPips() {
   if (_Digits == 2 || _Digits == 4) return _Point;
   return 10*_Point;
}



//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
