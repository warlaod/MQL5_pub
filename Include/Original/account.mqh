//+------------------------------------------------------------------+
//|                                                      account.mqh |
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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double SetLot(int denominator)
  {
   double lot = NormalizeDouble(AccountInfoDouble(ACCOUNT_BALANCE)/denominator, 2);
   if(lot < 0.1)
     {
      lot = 0.1;
     }
   if(lot > 50)
     {
      lot = 50;
     }
   return lot;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isNotEnoughMoney()
  {
   if(NormalizeDouble(AccountInfoDouble(ACCOUNT_BALANCE),1) < 2000)
     {
      return true;
     }
   return false;

  }
//+------------------------------------------------------------------+
