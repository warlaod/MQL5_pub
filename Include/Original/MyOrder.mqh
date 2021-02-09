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
#include <Trade\DealInfo.mqh>
#include <Original\MyUtils.mqh>

class MyOrder {
 public:
   int HistoryTotal;
   ENUM_TIMEFRAMES Timeframe;
   CHistoryOrderInfo HistoryOrderInfo;
   CDealInfo DealInfo;

   datetime last_bartime;
   datetime new_bartime;

   void MyOrder(ENUM_TIMEFRAMES Timeframe) {
      this.Timeframe = Timeframe;
   }

   void Refresh() {
      HistorySelect(0,TimeCurrent());
   }


   bool wasOrderedInTheSameBar() {
      
      HistoryOrderInfo.SelectByIndex(HistoryOrdersTotal() - 1);
      if( Bars(_Symbol, Timeframe, HistoryOrderInfo.TimeDone(), TimeCurrent()) == 0)
         return true;
      return false;
   }

};
//+------------------------------------------------------------------+
