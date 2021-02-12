//+------------------------------------------------------------------+
//|                                                    MyFractal.mqh |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
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
#include <Indicators\BillWilliams.mqh>
#include <Original\MyCalculate.mqh>

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class MyFractal:public CiFractals
  {
public:
   int               MHighestIndex;
   void              SearchMHighest(int disntancePips, int Period)
     {
      for(int i=2; i<Period; i++)
        {
         if(Maximum(0,i-1,3) == i)
           {
            MHighestIndex = i;
            return;
           }
        }
     }
  };
//+------------------------------------------------------------------+
