//+------------------------------------------------------------------+
//|                                                      MyOrder.mqh |
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
#include <Trade\OrderInfo.mqh>
#include <Trade\HistoryOrderInfo.mqh>
#include <Original\MyUtils.mqh>

class MyOrder {
 public:
   int HistoryTotal;

   void Refresh() {
      HistorySelect(0,TimeCurrent());
      HistoryTotal = HistoryOrdersTotal();
   }


   bool wasOrderedInTheSameBar(ENUM_TIMEFRAMES Timeframe) {
      CHistoryOrderInfo cHistoryOrderInfo;
      cHistoryOrderInfo.SelectByIndex(HistoryTotal-1);
      if(cHistoryOrderInfo.Magic() != MagicNumber) return false;
      int current = TimeCurrent();
      int timedone = cHistoryOrderInfo.TimeDone();
      int bars = Bars(_Symbol, Timeframe, cHistoryOrderInfo.TimeDone(), TimeCurrent());
      if(Bars(_Symbol, Timeframe, cHistoryOrderInfo.TimeDone(), TimeCurrent()) == 0 )
         return true;
      return false;
   }

};
//+------------------------------------------------------------------+
