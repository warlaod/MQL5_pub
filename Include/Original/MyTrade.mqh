//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

#include <Original\MyCalculate.mqh>
#include <Trade\Trade.mqh>

input int spread = -1;
input double risk = 50000;
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
   double ContractSize;
   double InitialDeposit;
   int LotDigits;
   MqlDateTime dt;
   CTrade trade;

   void MyTrade() {
      minlot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
      maxlot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
      InitialDeposit = NormalizeDouble(AccountInfoDouble(ACCOUNT_EQUITY), 1);
      ContractSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
      trade.SetDeviationInPoints(10);
      LotDigits = -MathLog10(minlot);
      topips = PriceToPips();
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
         if((TP - Ask)*topips < 2 || (Ask - SL)*topips < 2) return true;
      }
      else if(TP < SL) {
         if( (Bid - TP)*topips < 2  || (SL - Bid)*topips < 2) return true;
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
      if(trade.Buy(lot, NULL, Ask, SL, TP, NULL))
         return true;
      return false;
   }

   bool Sell(double SL, double TP) {
      if(signal != ORDER_TYPE_SELL) return false;
      if(isInvalidTrade(SL, TP)) return false;
      if(!ModifyLot(SL)) return false;
      if(trade.Sell(lot, NULL, Bid, SL, TP, NULL))
         return true;
      return false;
   }

   bool PositionModify(ulong ticket, double SL, double TP) {
      if(isInvalidTrade(SL, TP)) return false;
      if(trade.PositionModify(ticket, SL, TP)) return true;
      return false;
   }


 private:
   double topips;
   bool ModifyLot(double SL) {
      // double TradeRisk = MathAbs(SL - Ask) * topips;
      //if(TradeRisk == 0) return false;
      if(isLotModified) {
         lot = NormalizeDouble(AccountInfoDouble(ACCOUNT_EQUITY) / risk, LotDigits);
         //lot = NormalizeDouble(AccountInfoDouble(ACCOUNT_EQUITY) * risk / (ContractSize * TradeRisk), LotDigits);
      } else {
         lot = NormalizeDouble(InitialDeposit / risk, LotDigits);
         //lot = NormalizeDouble(InitialDeposit / risk / TradeRisk, LotDigits);
      }
      if(lot < minlot) lot = minlot;
      else if(lot > maxlot) lot = maxlot;

      return true;
   }

};
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
