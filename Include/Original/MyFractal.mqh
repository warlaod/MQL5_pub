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
class MyFractal:public CiFractals {
 public:
  int MHighestIndex;
  int KeySize;
  CHashMap<int, double > MUpper, MLower;

  void MyFractal(int KeySize) {
    this.KeySize = KeySize;
  }

  void myRefresh() {
    Refresh();
    setValue();
  }

  void setValue() {
    int i = 0;
    MUpper.Clear();
    MLower.Clear();
    while(MUpper.Count() < KeySize || i < 100) {
      if(Upper(i) != EMPTY_VALUE)
        MUpper.Add(MUpper.Count(), Upper(i));
      i++;
    }
    i = 0;
    while(MLower.Count() < KeySize || i < 100) {
      if(Lower(i) != EMPTY_VALUE)
        MLower.Add(MLower.Count(), Lower(i));
      i++;
    }
  }
};
//+------------------------------------------------------------------+
