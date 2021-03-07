//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
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
      HistorySelect(0, TimeCurrent());
   }

   bool wasOrderedInTheSameBar() {
      HistoryOrderInfo.SelectByIndex(HistoryOrdersTotal() - 1);
      if( Bars(_Symbol, Timeframe, HistoryOrderInfo.TimeDone(), TimeCurrent()) == 0)
         return true;
      return false;
   }
};
//+------------------------------------------------------------------+
