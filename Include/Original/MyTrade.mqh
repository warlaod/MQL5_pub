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
input int denom = 30000;

class MyTrade {

 public:
   bool istradable;
   string signal;
   double lot;
   void MyTrade(double lot) {
      istradable = false;
      signal = "";
      this.lot = lot;
   }

   void CheckSpread() {
      if(SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) < spread) {
         istradable = false;
      }
   }

   void SetLot() {
      lot = NormalizeDouble(AccountInfoDouble(ACCOUNT_EQUITY) / denom, 2);
      if(lot < 0.01) lot = 0.01;
      else if(lot > 50) lot = 50;
   }
   bool isPositionInRange(double Range, double CenterLine, ENUM_POSITION_TYPE PositionType) {

      CPositionInfo cPositionInfo;
      int PositionTotal = PositionsTotal();
      for(int i = PositionsTotal() - 1; i >= 0; i--) {
         cPositionInfo.SelectByTicket(PositionGetTicket(i));
         ENUM_POSITION_TYPE CType = cPositionInfo.PositionType();
         double PriceOpen = cPositionInfo.PriceOpen();
         if(cPositionInfo.PositionType() != PositionType) continue;

         if(MathAbs(cPositionInfo.PriceOpen() - CenterLine) < Range) {
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
