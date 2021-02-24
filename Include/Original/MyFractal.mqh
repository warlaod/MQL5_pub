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
#include <Generic\HashMap.mqh>

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class MyFractal: public CiFractals {
 public:
   int MHighestIndex;
   int KeySize;
   CArrayDouble SUpper, SLower, MUpper, MLower;

   void MyFractal(int KeySize) {
      this.KeySize = KeySize;
   }

   void myRefresh() {
      Refresh();
      SUpper.Clear();
      SLower.Clear();
      MUpper.Clear();
      MLower.Clear();
   }

   void SearchShort(int total) {
      int i = 0;
      while(SUpper.Total() < total) {
         if(Upper(i) != EMPTY_VALUE)
            SUpper.Add(Upper(i));
         i++;
      }
      i = 0;
      while(SLower.Total() < total) {
         if(Lower(i) != EMPTY_VALUE)
            SLower.Add(Lower(i));
         i++;
      }
   }

   void SearchMiddle(int total = 1) {
      int i = 0;
      while(MUpper.Total() < total) {
         if(Upper(i) != EMPTY_VALUE)
            SUpper.Add(Upper(i));
         i++;
         if(SUpper.Maximum(i - 1, 3) == 2)
            MUpper.Add(Upper(i));
      }
      i = 0;
      while(SLower.Total() < KeySize) {
         if(Lower(i) != EMPTY_VALUE)
            SLower.Add(Lower(i));
         i++;
      }
   }
};
//+------------------------------------------------------------------+
