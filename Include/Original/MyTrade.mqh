//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

#include <Original\MyCalculate.mqh>
#include <Trade\Trade.mqh>

input int spread = -1;
input int denom = 100000;
input int positions = 2;
input bool isLotModified = false;
input int StopBalance = 2000;
input int StopMarginLevel = 200;

class MyTrade {

 public:
   bool istradable;
   string signal;
   double lot;
   double Ask;
   double Bid;
   double balance;
   double minlot;
   double maxlot;
   int LotDigits;
   MqlDateTime dt;
   CTrade trade;

   void MyTrade() {
      minlot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
      maxlot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
      trade.SetDeviationInPoints(10);
      if(minlot == 0.001) LotDigits = 3;
      if(minlot == 0.01) LotDigits = 2;
      if(minlot == 0.1) LotDigits = 1;
      if(minlot == 1) LotDigits = 0;
      ModifyLot();
   }

   void Refresh() {
      if(isLotModified) ModifyLot();
      istradable = true;
      signal = "";

      Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
      Ask =  NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   }

   void setSignal(ENUM_ORDER_TYPE OrderType) {
      if(OrderType == ORDER_TYPE_BUY) signal = "buy";
      if(OrderType == ORDER_TYPE_SELL) signal = "sell";
   }

   void CheckSpread() {
      int currentSpread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
      if(spread == -1)
         return;
      if(currentSpread >= spread)
         istradable = false;
   }

   bool isInvalidTrade(double SL, double TP) {
      if(TP > SL) {
         if(TP - Ask < 25 * _Point || Ask - SL < 25 * _Point) return true;
      }

      else if(TP < SL) {
         if(Bid - TP < 25 * _Point  || SL - Bid < 25 * _Point) return true;
      }
      return false;
   }

   void CheckBalance() {
      if(NormalizeDouble(AccountInfoDouble(ACCOUNT_BALANCE), 1) < StopBalance) {
         istradable = false;
      }
   }

   void CheckMarginLevel() {
      double marginlevel = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
      if(marginlevel < StopMarginLevel && marginlevel != 0 ) istradable = false;
   }

   bool Buy(double SL, double TP) {
      if(signal != "buy") return false;
      if(isInvalidTrade(SL, TP)) return false;
      if(trade.Buy(lot, NULL, Ask, SL, TP, NULL)) return true;
      return false;
   }

   bool Sell(double SL, double TP) {
      if(signal != "sell") return false;
      if(isInvalidTrade(SL, TP)) return false;
      if(trade.Sell(lot, NULL, Bid, SL, TP, NULL)) return true;
      return false;
   }

   bool PositionModify(long identifier, double SL, double TP) {
      if(isInvalidTrade(SL, TP)) return false;
      if(trade.PositionModify(identifier, SL, TP)) return true;
      return false;
   }


 private:
   void ModifyLot() {
      lot = NormalizeDouble(AccountInfoDouble(ACCOUNT_EQUITY) / denom, LotDigits);
      if(lot < minlot) lot = minlot;
      else if(lot > maxlot) lot = maxlot;
   }

};
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
