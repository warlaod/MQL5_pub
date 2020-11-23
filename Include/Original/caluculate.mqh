//+------------------------------------------------------------------+
//|                                                   caluculate.mqh |
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
static double HighestVal;
static int HighestNum;
static double LowestVal;
static int LowestNum;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SearchHighest(double &array[])
  {
   HighestVal = -100;
   HighestNum = NULL;
   for(int i = 0; i < ArraySize(array); i++)
     {
      if(array[i] > HighestVal)
        {
         HighestVal = array[i];
         HighestNum = i;
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SearchLowest(double &array[])
  {
   LowestVal = 100;
   LowestNum = NULL;
   for(int i = 0; i < ArraySize(array); i++)
     {
      if(array[i] < LowestVal)
        {
         LowestVal = array[i];
         LowestNum = i;
        }
     }
  }
//+------------------------------------------------------------------+
