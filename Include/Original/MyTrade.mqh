//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

#include <Original\MyCalculate.mqh>
#include <Trade\Trade.mqh>

input int spread = -1;
input double risk = 0.0001;
input int positions = 2;
input bool isLotModified = false;
input int StopBalance = 2000;
input int StopMarginLevel = 300;

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
   double InitialDeposit;
   int LotDigits;
   MqlDateTime dt;
   CTrade trade;

   void MyTrade() {
      minlot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
      maxlot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
      InitialDeposit = NormalizeDouble(AccountInfoDouble(ACCOUNT_EQUITY), 1);
      trade.SetDeviationInPoints(10);
      if(minlot == 0.001) LotDigits = 3;
      if(minlot == 0.01) LotDigits = 2;
      if(minlot == 0.1) LotDigits = 1;
      if(minlot == 1) LotDigits = 0;
   }

   void Refresh() {
      istradable = true;
      signal = "";

      Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
      Ask =  NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   }

   void setSignal(ENUM_ORDER_TYPE OrderType) {
      signal = OrderType;
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
      if(signal != ORDER_TYPE_BUY) return false;
      if(isInvalidTrade(SL, TP)) return false;
      if(!ModifyLot(SL)) return false;
      if(trade.Buy(lot, NULL, Ask, SL, TP, NULL)) return true;
      return false;
   }

   bool Sell(double SL, double TP) {
      if(signal != ORDER_TYPE_SELL) return false;
      if(isInvalidTrade(SL, TP)) return false;
      if(!ModifyLot(SL)) return false;
      if(trade.Sell(lot, NULL, Bid, SL, TP, NULL)) return true;
      return false;
   }

   bool PositionModify(long identifier, double SL, double TP) {
      if(isInvalidTrade(SL, TP)) return false;
      if(trade.PositionModify(identifier, SL, TP)) return true;
      return false;
   }


 private:
   bool ModifyLot(double SL) {
      double TradeRisk = MathAbs(SL - Ask) / (10 * _Point);
      if(TradeRisk == 0) return false;
      if(isLotModified) {
         lot = NormalizeDouble(InitialDeposit * risk / TradeRisk, LotDigits);
      } else {
         lot = NormalizeDouble(AccountInfoDouble(ACCOUNT_EQUITY) * risk / TradeRisk, LotDigits);
      }
      if(lot < minlot) lot = minlot;
      else if(lot > maxlot) lot = maxlot;

      return true;
   }

};
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
