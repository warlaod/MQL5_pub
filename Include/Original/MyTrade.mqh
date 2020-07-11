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
      if( cSymbolInfo.Spread() < spread) {
         istradable = false;
      }
   }
   bool isPositionInRange(double Range, double CenterLine, ENUM_POSITION_TYPE PositionType) {
      CPositionInfo cPositionInfo;

      for(int i = PositionsTotal() - 1; i >= 0; i--) {
         cPositionInfo.Select(_Symbol);
         if(cPositionInfo.Type() != PositionType) continue;
         if(isBetween(CenterLine + Range, CenterLine - Range, cPositionInfo.PriceOpen())) {
            return true;
         }
      }
      return false;
   }

   double Bid() {
      return cSymbolInfo.Bid();
   }
   
   double Ask() {
      return cSymbolInfo.Ask();
   }
 private:
   CSymbolInfo cSymbolInfo;
};
//+------------------------------------------------------------------+
