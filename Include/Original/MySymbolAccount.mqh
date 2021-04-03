//+------------------------------------------------------------------+
//|                                                    MyAccount.mqh |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"


#include <Trade\AccountInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Original\MyTrade.mqh>

input int StopBalance = 1000;
input int StopMarginLevel = 200;
input int spread = -1;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class MySymbolAccount {
 public:
   CAccountInfo AI;
   CSymbolInfo SI;
   double balance;
   double minlot;
   double maxlot;
   double currentSpread;
   int LotDigits;
   bool isTradable;
   double StopsLevel;

   void MySymbolAccount() {
      minlot = SI.LotsMin();
      maxlot = SI.LotsMax();
      LotDigits = -MathLog10(SI.LotsStep());
      StopsLevel = SI.StopsLevel() * PointToPips();
   }
   
   void CheckSpread() {
      currentSpread = SI.Spread();
      if(spread == -1)
         return;
      if(currentSpread >= spread)
         IsCurrentTradable = false;
   }
   
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double PriceToPips() {
   double pips = 1;
   // 現在の通貨ペアの小数点以下の桁数を取得
   int digits = _Digits;
   // 3桁・5桁のFXブローカーの場合
   if(digits == 3 || digits == 5) {
      pips = MathPow(10, digits) / 10;
   }
   // 2桁・4桁のFXブローカーの場合
   if(digits == 2 || digits == 4) {
      pips = MathPow(10, digits);
   }
   // 少数点以下を１桁に丸める（目的によって桁数は変更する）
   pips = NormalizeDouble(pips, 1);
   return(pips);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double PointToPips() {
   if (_Digits == 2 || _Digits == 4) return _Point;
   return 10 * _Point;
}
//+------------------------------------------------------------------+
double pointToPips = PointToPips();
double priceToPips = PriceToPips();