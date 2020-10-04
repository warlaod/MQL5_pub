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
#include <Original\MyCalculate.mqh>
#include <Tools\DateTime.mqh>

// input bool SetDSTOnUSA;
// input bool SetDSTOnEU;
input int FridayEndHour = 23;
class MyDate {
 public:
   CDateTime dt;
   bool isDSTOnUSA;
   bool isDSTOnEU;
   void MyDate() {

   }

   void Refresh() {
      TimeToStruct(TimeCurrent(), dt);
      // if(SetDSTOnEU) {
      //    checkDST_EU();
      //    if(isDSTOnEU) TimeToStruct(TimeCurrent() + 3600, dt);
      // } else if(SetDSTOnUSA) {
      //    checkDST_USA();
      //    if(isDSTOnUSA) TimeToStruct(TimeCurrent() + 3600, dt);
      //    double dawdwa = 123;
      // }
   }

   bool isYearEnd() {
      if(dt.mon == 12 && dt.day > 25) return true;
      if(dt.mon == 1 && dt.day < 5) return true;
      return false;
   }

   bool isFridayEnd() {
      if(dt.day_of_week == SATURDAY) {
         if((dt.hour == FridayEndHour - 1 && dt.min > 0) || dt.hour >= FridayEndHour)
            return true;
      }
      return false;
   }

   void checkDST_USA() {
      double CurrentTime = TimeCurrent();
      double StartTime = StringToTime(StringFormat("%04d-%02d-%02d", dt.year, 3, DST_USA_Startday()));
      double EndTime = StringToTime(StringFormat("%04d-%02d-%02d", dt.year, 11, DST_USA_Endday()));
      if(isBetween(EndTime, CurrentTime, StartTime))
         isDSTOnUSA = true;
      else
         isDSTOnUSA = false;
   }

   void checkDST_EU() {
      double CurrentTime = TimeCurrent();
      double StartTime = StringToTime(StringFormat("%04d-%02d-%02d", dt.year, 3, DST_EU_Startday()));
      double EndTime = StringToTime(StringFormat("%04d-%02d-%02d", dt.year, 10, DST_EU_Endday()));
      if(isBetween(EndTime, CurrentTime, StartTime))
         isDSTOnEU = true;
      else
         isDSTOnEU = false;
   }

 private:

   int DST_USA_Startday() {
      CDateTime StartDt;
      StartDt.Year(dt.year);
      StartDt.Mon(3);
      for(int day = 8; day <= 14; day++) {
         StartDt.Day(day);
         if(StartDt.day_of_week == SUNDAY) break;
      }
      return StartDt.day;
   }

   int DST_USA_Endday() {
      CDateTime EndDt;
      EndDt.Year(dt.year);
      EndDt.Mon(11);
      for(int day = 1; day <= 7; day++) {
         EndDt.Day(day);
         if(EndDt.day_of_week == SUNDAY) break;
      }
      return EndDt.day;
   }

   int DST_EU_Startday() {
      CDateTime StartDt;
      StartDt.Year(dt.year);
      StartDt.Mon(3);
      for(int day = 25; day <= 31; day++) {
         StartDt.Day(day);
         if(StartDt.day_of_week == SUNDAY) break;
      }
      return StartDt.day;
   }

   int DST_EU_Endday() {
      CDateTime EndDt;
      EndDt.Year(dt.year);
      EndDt.Mon(10);
      for(int day = 25; day <= 31; day++) {
         EndDt.Day(day);
         if(EndDt.day_of_week == SUNDAY) break;
      }
      return EndDt.day;
   }








//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   void check_DST_EU(int month, int day, int hour, int day_of_week) {

      if(day_of_week == MONDAY) {
         if(month == 3 && 25 < day && day <= 31) {
         }
      }

      if(day_of_week == MONDAY) {
         if(month == 10 && 25 < day && day <= 31) {
         }
      }
   }


};
//+------------------------------------------------------------------+
