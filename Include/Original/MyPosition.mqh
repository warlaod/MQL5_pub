//+------------------------------------------------------------------+
//|                                                   MyPosition.mqh |
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
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

class MyPosition {
 public:
   MqlDateTime dt;
   int Total;

   void Refresh() {
      Total = PositionsTotal();
   }

   bool isPositionInRange(double Range, double CenterLine, ENUM_POSITION_TYPE PositionType) {
      for(int i = Total - 1; i >= 0; i--) {
         cPositionInfo.SelectByTicket(PositionGetTicket(i));
         if(cPositionInfo.PositionType() != PositionType) continue;
         if(MathAbs(cPositionInfo.PriceOpen() - CenterLine) < Range) {
            return true;
         }
      }
      return false;
   }

   void CloseAllPositions(ENUM_POSITION_TYPE PositionType) {
      CTrade itrade;
      for(int i = Total - 1; i >= 0; i--) {
         cPositionInfo.SelectByTicket(PositionGetTicket(i));
         if(cPositionInfo.PositionType() != PositionType) continue;
         itrade.PositionClose(PositionGetTicket(i));
      }
   }

   int TotalEachPositions(ENUM_POSITION_TYPE PositionType) {
      CTrade itrade;
      int count = 0;
      for(int i = Total - 1; i >= 0; i--) {
         cPositionInfo.SelectByTicket(PositionGetTicket(i));
         if(cPositionInfo.PositionType() != PositionType) continue;
         count++;
      }
      return count;
   }

   void Trailings(ENUM_POSITION_TYPE PositionType,double SL) {
      CTrade itrade;
      for(int i = Total - 1; i >= 0; i--) {
         cPositionInfo.SelectByTicket(PositionGetTicket(i));
         if(cPositionInfo.PositionType() != PositionType) continue;
         if(MathAbs(cPositionInfo.StopLoss() - cPositionInfo.PriceCurrent()) < MathAbs(SL-cPositionInfo.PriceCurrent())) continue;
         if(PositionType == POSITION_TYPE_BUY) {
            itrade.PositionModify(cPositionInfo.Identifier(),SL,cPositionInfo.PriceCurrent()+10*_Point );
         } else if(PositionType == POSITION_TYPE_SELL) {
            itrade.PositionModify(cPositionInfo.Identifier(),SL,cPositionInfo.PriceCurrent()-10*_Point );
         }
      }
   }

 private:
   CPositionInfo cPositionInfo;
};
//+------------------------------------------------------------------+
