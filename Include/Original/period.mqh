//+------------------------------------------------------------------+
//|                                                       period.mqh |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#include <Original\positions.mqh>
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
ENUM_TIMEFRAMES Timeframe(int period_num)
  {
   if(period_num == 1)
     {
      return PERIOD_M1;
     }
   if(period_num == 2)
     {
      return PERIOD_M2;
     }
   if(period_num == 3)
     {
      return PERIOD_M3;
     }
   if(period_num == 4)
     {
      return PERIOD_M5;
     }
   if(period_num == 5)
     {
      return PERIOD_M10;
     }
   if(period_num == 6)
     {
      return PERIOD_M12;
     }
   if(period_num == 7)
     {
      return PERIOD_M15;
     }
   if(period_num == 8)
     {
      return PERIOD_M20;
     }
   if(period_num == 9)
     {
      return PERIOD_M30;
     }
   if(period_num == 10)
     {
      return PERIOD_H1;
     }
   if(period_num == 11)
     {
      return PERIOD_H2;
     }
   if(period_num == 12)
     {
      return PERIOD_H3;
     }
   if(period_num == 13)
     {
      return PERIOD_H4;
     }
   if(period_num == 14)
     {
      return PERIOD_H6;
     }
   if(period_num == 15)
     {
      return PERIOD_H8;
     }
   if(period_num == 16)
     {
      return PERIOD_H12;
     }
   if(period_num == 17)
     {
      return PERIOD_D1;
     }
   if(period_num == 18)
     {
      return PERIOD_W1;
     }
   return PERIOD_CURRENT;
  }




//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isTradableJP(int &cant_hours[], int current_hour)
  {
   for(int i = 0; i < ArraySize(cant_hours); i++)
     {
      if(cant_hours[i] == current_hour)
        {
         return false;
        }
     }
   return true;
  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static bool summer_USA = false;
void check_summer_USA(int month,int day, int hour,int day_of_week)
  {
   if(month ==3 && day_of_week == MONDAY && summer_USA == false)
     {
      if(8 < day && day <=15)
        {
         summer_USA =true;
        }
     }
   if(month == 11 && day_of_week == MONDAY && summer_USA == true)
     {
      if(1<day && day <=8)
        {
         summer_USA =false;
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isTradableUSA(int &cant_hours_USA[], int hour)
  {
   if(summer_USA)
     {
      hour = (hour+1)%24;
     }

   for(int i = 0; i < ArraySize(cant_hours_USA); i++)
     {
      if(cant_hours_USA[i] == hour)
        {
         return false;
        }
     }
   return true;
  }




//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static bool summer_EU = false;
void check_summer_EU(int month,int day, int hour,int day_of_week)
  {
   if(day_of_week == MONDAY && summer_EU == false)
     {
      if(month == 3 && 25 < day && day <=31)
        {
         summer_EU =true;
        }
      else
         if(month == 4 && day == 1)
           {
            summer_EU =true;
           }
     }

   if(day_of_week == MONDAY && summer_EU == true)
     {
      if(month == 10 && 25 < day && day <=31)
        {
         summer_EU =false;
        }
      else
         if(month == 11 && day == 1)
           {
            summer_EU =false;
           }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isTradableEU(int &cant_hours_EU[], int hour)
  {
   if(summer_EU)
     {
      hour = (hour+1)%24;
     }

   for(int i = 0; i < ArraySize(cant_hours_EU); i++)
     {
      if(cant_hours_EU[i] == hour)
        {
         return false;
        }
     }
   return true;
  }
  
 bool isYearEnd(int month,int day)
  {
   if(month == 12 && day > 25)
     {
      CloseAllBuyPositions();
      CloseAllSellPositions();
      return true;
     }
   if(month == 1 && day < 5){
      CloseAllBuyPositions();
      CloseAllSellPositions();
      return true;
   }
   return false;
   }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+





//+------------------------------------------------------------------+
