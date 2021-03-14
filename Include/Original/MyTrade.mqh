//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#include <Original\MyCalculate.mqh>
#include <Trade\Trade.mqh>

input int spread = -1;
input double risk = 50000;
input double Lot = 0.1;
input bool isLotModified = false;
input int StopBalance = 2000;
input int StopMarginLevel = 300;

class MyTrade: public CTrade {
 public:
   bool isCurrentTradable;
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
   bool isTradable;
   double StopLossLevel;

   void MyTrade() {
      minlot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
      maxlot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
      InitialDeposit = NormalizeDouble(AccountInfoDouble(ACCOUNT_EQUITY), 1);
      ContractSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
      SetDeviationInPoints(10);
      LotDigits = -MathLog10(minlot);
      topips = PriceToPips();
      lot = NormalizeDouble(Lot, LotDigits);
      StopLossLevel =  NormalizeDouble(SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL), _Digits);
      InitializeLot();
   }

   void Refresh() {
      isCurrentTradable = true;
      signal = NULL;
      Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
      Ask =  NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
      ModifyLot();
   }

   void setSignal(ENUM_ORDER_TYPE OrderType) {
      signal = OrderType;
   }

   void CheckSpread() {
      int currentSpread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
      if(spread == -1)
         return;
      if(currentSpread >= spread)
         isCurrentTradable = false;
   }

   bool isInvalidTrade(double SL, double TP) {
      if(TP > SL) {
         if((TP - Ask)*topips < 2 || (Ask - SL)*topips < 2) return true;
      } else {
         if( (Bid - TP)*topips < 2  || (SL - Bid)*topips < 2) return true;
      }
      return false;
   }

   bool isInvalidStopTrade(double Price, double SL, double TP) {
      if(TP > SL) {
         if((Price - Ask)*topips < 2) return true;
         if((TP - Price)*topips < 2 || (Price - SL)*topips < 2) return true;
      } else {
         if((Bid - Price)*topips < 2) return true;
         if( (Price - TP)*topips < 2  || (SL - Price)*topips < 2) return true;
      }
      return false;
   }
   
   bool isInvalidLimitTrade(double Price, double SL, double TP) {
      if(TP > SL) {
         if((Ask - Price)*topips < 2) return true;
         if((TP - Price)*topips < 2 || (Price - SL)*topips < 2) return true;
      } else {
         if((Price - Bid)*topips < 2) return true;
         if( (Price - TP)*topips < 2  || (SL - Price)*topips < 2) return true;
      }
      return false;
   }

   bool isLowerBalance() {
      if(NormalizeDouble(AccountInfoDouble(ACCOUNT_BALANCE), 1) < StopBalance) return true;
      return false;
   }

   bool isLowerMarginLevel() {
      double marginlevel = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
      if(marginlevel < StopMarginLevel && marginlevel != 0 ) return true;
      return false;
   }

   void Buy(double SL, double TP) {
      if(signal != ORDER_TYPE_BUY) return;
      if(isInvalidTrade(SL, TP)) return;
      Buy(lot, NULL, Ask, SL, TP, NULL);
   }

   void ForceBuy(double SL, double TP) {
      if(isInvalidTrade(SL, TP)) return;
      Buy(lot, NULL, Ask, SL, TP, NULL);
   }

   void Sell(double SL, double TP) {
      if(signal != ORDER_TYPE_SELL) return;
      if(isInvalidTrade(SL, TP)) return;
      Sell(lot, NULL, Bid, SL, TP, NULL);
   }

   void ForceSell(double SL, double TP) {
      if(isInvalidTrade(SL, TP)) return;
      Sell(lot, NULL, Bid, SL, TP, NULL);
   }

   bool PositionModify(ulong ticket, double SL, double TP) {
      if(isInvalidTrade(SL, TP)) return false;
      if(PositionModify(ticket, SL, TP)) return true;
      return false;
   }

   void BuyStop(double Price, double SL, double TP) {
      if(isInvalidStopTrade(Price, SL, TP)) return;
      BuyStop(lot, Price, _Symbol, SL, TP);
   }

   void SellStop(double Price, double SL, double TP) {
      if(isInvalidStopTrade(Price, SL, TP)) return;
      SellStop(lot, Price, _Symbol, SL, TP);
   }

   void BuyLimit(double Price, double SL, double TP) {
      if(isInvalidStopTrade(Price, SL, TP)) return;
      BuyLimit(lot, Price, _Symbol, SL, TP);
   }

   void SellLimit(double Price, double SL, double TP) {
      if(isInvalidStopTrade(Price, SL, TP)) return;
      SellLimit(lot, Price, _Symbol, SL, TP);
   }




 private:
   double topips;
   void ModifyLot() {
      // double TradeRisk = MathAbs(SL - Ask) * topips;
      //if(TradeRisk == 0) return false;
      if(!isLotModified) return;
      lot = NormalizeDouble(AccountInfoDouble(ACCOUNT_EQUITY) / risk, LotDigits);
      //lot = NormalizeDouble(AccountInfoDouble(ACCOUNT_EQUITY) * risk / (ContractSize * TradeRisk), LotDigits);
      //lot = NormalizeDouble(InitialDeposit / risk / TradeRisk, LotDigits);
      if(lot < minlot) lot = minlot;
      else if(lot > maxlot) lot = maxlot;
   }

   void InitializeLot() {
      lot = NormalizeDouble(lot, LotDigits);
      if(lot < minlot) lot = minlot;
      else if(lot > maxlot) lot = maxlot;
   }
};
//+------------------------------------------------------------------+
