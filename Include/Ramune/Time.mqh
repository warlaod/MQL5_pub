//+------------------------------------------------------------------+
//|                                                       MyDate.mqh |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
// #define MacrosHello   "Hello, world!"
#include <Tools\DateTime.mqh>

class Time {
 public:
   CDateTime dt;
   datetime  timeCurrent;

   void Refresh() {
      TimeToStruct( TimeCurrent(), dt);
   }

   bool isYearEnd() {
      if(dt.mon == 12 && dt.day > 25) return true;
      if(dt.mon == 1 && dt.day < 5) return true;
      return false;
   }

   bool isMondayStart() {
      if(dt.day_of_week == MONDAY && dt.hour <= 3)
         return true;
      return false;
   }


   bool CheckTimeOver(ENUM_DAY_OF_WEEK dayOfWeek, int hour) {
      if(dt.day_of_week == dayOfWeek && dt.hour >= hour) return true;
      return false;
   }
};
//+------------------------------------------------------------------+
