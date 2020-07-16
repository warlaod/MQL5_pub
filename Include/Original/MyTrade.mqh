//+------------------------------------------------------------------+
//|                                                      MyTrade.mqh |
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
input int spread;
input int denom = 30000;
input int positions = 2;

class MyTrade {

 public:
   bool istradable;
   string signal;
   double lot;
   double Ask;
   double Bid;
   double balance;
   MqlDateTime dt;

   void MyTrade(double lot, bool isSetLot) {
      balance = NormalizeDouble(AccountInfoDouble(ACCOUNT_BALANCE),1);
      Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
      Ask =  NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
      TimeToStruct(TimeCurrent(), dt);
      istradable = true;
      signal = "";
      if(isSetLot) {
         SetLot();
      } else {
         this.lot = lot;
      }
   }
   
   void CheckSpread() {
      if(SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) >= spread) {
         istradable = false;
      }
   }


   bool isInvalidTrade(double SL, double TP) {
      if(TP > SL) {
         if(TP - Ask < 20 * _Point || Ask - SL < 20 * _Point) return true;
      }

      else if(TP < SL) {
         if(Bid - TP < 20 * _Point  || SL - Bid < 20 * _Point) return true;
      }
      return false;
   }

   void CheckYearsEnd() {
      if(dt.mon == 12 && dt.day > 25) {
         istradable =  false;
      }
      if(dt.mon == 1 && dt.day < 5) {
         istradable = false;
      }
   }

   void CheckFridayEnd() {
      if(dt.day_of_week == FRIDAY) {
         if((dt.hour == 22 && dt.min > 0) || dt.hour == 23) {
            istradable = false;
         }
      }
   }
   
   void CheckBalance(){
      if(balance < 2000){
         istradable = false;
      }
   }



 private:
   void SetLot() {
      lot = NormalizeDouble(AccountInfoDouble(ACCOUNT_EQUITY) / denom, 2);
      if(lot < 0.01) lot = 0.01;
      else if(lot > 50) lot = 50;
   }

};
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
