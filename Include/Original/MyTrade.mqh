//+------------------------------------------------------------------+
//|                                                      MyTrade.mqh |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
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
#include <Trade\SymbolInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Original\MyCalculate.mqh>
input int spread;

class MyTrade {

 public:
   bool istradable;
   string signal;
   void MyTrade() {
      istradable = false;
      signal = "";
   }

   void CheckSpread() {
      if(SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) < spread) {
         istradable = false;
      }
   }
   bool isPositionInRange(double Range, double CenterLine, ENUM_POSITION_TYPE PositionType) {
      CPositionInfo cPositionInfo;

      for(int i = PositionsTotal() - 1; i >= 0; i--) {
         cPositionInfo.Select(_Symbol);
         ENUM_POSITION_TYPE dwa = cPositionInfo.Type();
         bool dwad = cPositionInfo.PositionType() != PositionType;
         if(cPositionInfo.PositionType() != PositionType) continue;
         if(isBetween(CenterLine + Range, CenterLine - Range, cPositionInfo.PriceOpen())) {
            return true;
         }
      }
      return false;
   }

   bool isInvalidTrade(double SL, double TP) {
      if(TP > SL) {
         double Ask = Ask();
         if(TP - Ask < 20 * _Point || Ask - SL < 20 * _Point) return true;
      }
      
      else if(TP < SL) {
         double Bid = Bid();
         if(Bid - TP < 20 * _Point  || SL - Bid < 20 * _Point) return true;
      }
      return false;
   }

   double Bid() {
      return NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   }

   double Ask() {
      return NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   }
};
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
