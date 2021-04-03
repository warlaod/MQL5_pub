//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#include <Original\MyCalculate.mqh>
#include <Original\MySymbolAccount.mqh>
#include <Trade\Trade.mqh>


input double risk = 50000;
input double Lot = 0.1;
input bool isLotModified = false;


ENUM_ORDER_TYPE Signal;
bool IsTradable, IsCurrentTradable;

class MyTrade: public CTrade {
 public:
   double lot;
   double Ask;
   double Bid;
   double balance;
   MySymbolAccount SA;

   void MyTrade() {
      SetDeviationInPoints(10);
      lot = NormalizeDouble(Lot, SA.LotDigits);
      InitializeLot();
   }

   void Refresh() {
      Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
      Ask =  NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   }

   bool isInvalidTrade(double SL, double TP) {
      if(TP > SL) {
         if((TP - Ask)*priceToPips < SA.StopsLevel || (Ask - SL)*priceToPips < SA.StopsLevel) return true;
      } else {
         if( (Bid - TP)*priceToPips < SA.StopsLevel  || (SL - Bid)*priceToPips < SA.StopsLevel) return true;
      }
      return false;
   }

   bool isInvalidStopTrade(double Price, double SL, double TP) {
      if(TP > SL) {
         if((Price - Ask)*priceToPips < SA.StopsLevel) return true;
         if((TP - Price)*priceToPips < SA.StopsLevel || (Price - SL)*priceToPips < SA.StopsLevel) return true;
      } else {
         if((Bid - Price)*priceToPips < SA.StopsLevel) return true;
         if( (Price - TP)*priceToPips < SA.StopsLevel  || (SL - Price)*priceToPips < SA.StopsLevel) return true;
      }
      return false;
   }

   bool isInvalidLimitTrade(double Price, double SL, double TP) {
      if(TP > SL) {
         if((Ask - Price)*priceToPips < SA.StopsLevel) return true;
         if((TP - Price)*priceToPips < SA.StopsLevel || (Price - SL)*priceToPips < SA.StopsLevel) return true;
      } else {
         if((Price - Bid)*priceToPips < SA.StopsLevel) return true;
         if( (Price - TP)*priceToPips < SA.StopsLevel  || (SL - Price)*priceToPips < SA.StopsLevel) return true;
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
      if(isInvalidTrade(SL, TP)) return;
      Buy(ModifiedLot(), NULL, Ask, SL, TP, NULL);
   }

   void ForceBuy(double SL, double TP) {
      if(isInvalidTrade(SL, TP)) return;
      Buy(ModifiedLot(), NULL, Ask, SL, TP, NULL);
   }
   
   void ForceBuy(double SL, double TP,double Selllot) {
      if(isInvalidTrade(SL, TP)) return;
      Buy(Selllot, NULL, Bid, SL, TP, NULL);
   }

   void Sell(double SL, double TP) {
      if(isInvalidTrade(SL, TP)) return;
      Sell(ModifiedLot(), NULL, Bid, SL, TP, NULL);
   }

   void ForceSell(double SL, double TP) {
      if(isInvalidTrade(SL, TP)) return;
      Sell(ModifiedLot(), NULL, Bid, SL, TP, NULL);
   }
   
   void ForceSell(double SL, double TP,double Selllot) {
      if(isInvalidTrade(SL, TP)) return;
      Sell(Selllot, NULL, Bid, SL, TP, NULL);
   }

   bool PositionModify(ulong ticket, double SL, double TP) {
      if(isInvalidTrade(SL, TP)) return false;
      if(PositionModify(ticket, SL, TP)) return true;
      return false;
   }

   void BuyStop(double Price, double SL, double TP) {
      if(isInvalidStopTrade(Price, SL, TP)) return;
      BuyStop(ModifiedLot(), Price, _Symbol, SL, TP);
   }

   void SellStop(double Price, double SL, double TP) {
      if(isInvalidStopTrade(Price, SL, TP)) return;
      SellStop(ModifiedLot(), Price, _Symbol, SL, TP);
   }

   void BuyLimit(double Price, double SL, double TP) {
      if(isInvalidLimitTrade(Price, SL, TP)) return;
      BuyLimit(ModifiedLot(), Price, _Symbol, SL, TP);
   }

   void SellLimit(double Price, double SL, double TP) {
      if(isInvalidLimitTrade(Price, SL, TP)) return;
      SellLimit(ModifiedLot(), Price, _Symbol, SL, TP);
   }

 private:
   double ModifiedLot() {
      // double TradeRisk = MathAbs(SL - Ask) * priceToPips;
      //if(TradeRisk == 0) return false;
      if(!isLotModified) return lot;
      lot = NormalizeDouble(AccountInfoDouble(ACCOUNT_EQUITY) / risk, SA.LotDigits);
      //lot = NormalizeDouble(AccountInfoDouble(ACCOUNT_EQUITY) * risk / (ContractSize * TradeRisk), SA.LotDigits);
      //lot = NormalizeDouble(InitialDeposit / risk / TradeRisk, SA.LotDigits);
      if(lot < SA.MinLot) lot = SA.MinLot;
      else if(lot > SA.MaxLot) lot = SA.MaxLot;
      return lot;
   }

   void InitializeLot() {
      lot = NormalizeDouble(lot, SA.LotDigits);
      if(lot < SA.MinLot) lot = SA.MinLot;
      else if(lot > SA.MaxLot) lot = SA.MaxLot;
   }
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void setSignal(ENUM_ORDER_TYPE OrderType) {
   Signal = OrderType;
}
//+------------------------------------------------------------------+
