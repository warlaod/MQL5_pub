//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

#include <Trade\OrderInfo.mqh>
#include <Trade\HistoryOrderInfo.mqh>
#include <Original\MyUtils.mqh>
#include <Arrays\ArrayLong.mqh>

class MyHistory: public CHistoryOrderInfo {
 public:
   int HistoryTotal;
   int Total;
   ENUM_TIMEFRAMES Timeframe;

   datetime last_bartime;
   datetime new_bartime;

   void MyHistory(ENUM_TIMEFRAMES Timeframe) {
      this.Timeframe = Timeframe;
   }

   void Refresh() {
      HistorySelect(0, TimeCurrent());
   }

   bool wasOrderedInTheSameBar() {
      SelectByIndex(HistoryOrdersTotal() - 1);
      if( Bars(_Symbol, Timeframe, TimeDone(), TimeCurrent()) == 0)
         return true;
      return false;
   }

};
//+------------------------------------------------------------------+
