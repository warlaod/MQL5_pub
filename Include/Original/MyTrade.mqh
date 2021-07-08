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
      ModifiedLot();
   }

   bool isInvalidTrade(double SL, double TP) {
      if(TP > SL) {
         if((TP - Bid) < SA.StopsLevel || (Bid - SL) < SA.StopsLevel) return true;
      } else {
         if( (Ask - TP) < SA.StopsLevel  || (SL - Ask) < SA.StopsLevel) return true;
      }
      return false;
   }

   bool isInvalidStopTrade(double Price, double SL, double TP) {
      Price = NormalizeDouble(Price,_Digits);
      TP = NormalizeDouble(TP,_Digits);
      SL = NormalizeDouble(SL,_Digits);
      if(TP > SL) {
         if((Price - Ask) <= SA.StopsLevel) return true;
         if((TP - Price) <= SA.StopsLevel || (Price - SL) <= SA.StopsLevel) return true;
      } else {
         if((Bid - Price) <= SA.StopsLevel) return true;
         if( (Price - TP) <= SA.StopsLevel  || (SL - Price) <= SA.StopsLevel) return true;
      }
      return false;
   }

   bool isInvalidLimitTrade(double Price, double SL, double TP) {
      if(TP > SL) {
         if((Ask - Price) < SA.StopsLevel) return true;
         if((TP - Price) < SA.StopsLevel || (Price - SL) < SA.StopsLevel) return true;
      } else {
         if((Price - Bid) < SA.StopsLevel) return true;
         if( (Price - TP) < SA.StopsLevel  || (SL - Price) < SA.StopsLevel) return true;
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
      if(isNotEnoughMoneyToTrade(lot,Ask,ORDER_TYPE_BUY)) return;
      Buy(lot, NULL, Ask, SL, TP, NULL);
   }

   void ForceBuy(double SL, double TP) {
      if(isInvalidTrade(SL, TP)) return;
      if(isNotEnoughMoneyToTrade(lot,Ask,ORDER_TYPE_BUY)) return;
      Buy(lot, NULL, Ask, SL, TP, NULL);
   }

   void ForceBuy(double SL, double TP, double Buylot) {
      if(isInvalidTrade(SL, TP)) return;
      if(isNotEnoughMoneyToTrade(lot,Ask,ORDER_TYPE_BUY)) return;
      Buy(Buylot, NULL, Ask, SL, TP, NULL);
   }

   void Sell(double SL, double TP) {
      if(isInvalidTrade(SL, TP)) return;
      if(isNotEnoughMoneyToTrade(lot,Bid,ORDER_TYPE_SELL)) return;
      Sell(lot, NULL, Bid, SL, TP, NULL);
   }

   void ForceSell(double SL, double TP) {
      if(isInvalidTrade(SL, TP)) return;
      if(isNotEnoughMoneyToTrade(lot,Bid,ORDER_TYPE_SELL)) return;
      Sell(lot, NULL, Bid, SL, TP, NULL);
   }

   void ForceSell(double SL, double TP, double Selllot) {
      if(isInvalidTrade(SL, TP)) return;
      if(isNotEnoughMoneyToTrade(Selllot,Bid,ORDER_TYPE_SELL)) return;
      Sell(Selllot, NULL, Bid, SL, TP, NULL);
   }

   bool PositionModify(ulong ticket, double SL, double TP) {
      if(isInvalidTrade(SL, TP)) return false;
      if(PositionModify(ticket, SL, TP)) return true;
      return false;
   }

   void BuyStop(double Price, double SL, double TP) {
      if(isInvalidStopTrade(Price, SL, TP)) return;
      if(isNotEnoughMoneyToTrade(lot,Price,ORDER_TYPE_BUY_STOP)) return;
      BuyStop(lot, Price, _Symbol, SL, TP);
   }

   void SellStop(double Price, double SL, double TP) {
      if(isInvalidStopTrade(Price, SL, TP)) return;
      if(isNotEnoughMoneyToTrade(lot,Price,ORDER_TYPE_SELL_STOP)) return;
      SellStop(lot, Price, _Symbol, SL, TP);
   }

   void BuyLimit(double Price, double SL, double TP) {
      if(isInvalidLimitTrade(Price, SL, TP)) return;
      if(isNotEnoughMoneyToTrade(lot,Price,ORDER_TYPE_BUY_LIMIT)) return;
      BuyLimit(lot, Price, _Symbol, SL, TP);
   }

   void SellLimit(double Price, double SL, double TP) {
      if(isInvalidLimitTrade(Price, SL, TP)) return;
      if(isNotEnoughMoneyToTrade(lot,Price,ORDER_TYPE_SELL_LIMIT)) return;
      SellLimit(lot, Price, _Symbol, SL, TP);
   }

   bool isNotEnoughMoneyToTrade(double lot, double priceToOrder, ENUM_ORDER_TYPE type) {
      double marginToOrder;
      SA.Refresh();
      OrderCalcMargin(type, _Symbol, lot, priceToOrder, marginToOrder);
      double next_margin_level = SA.equity / (SA.margin + marginToOrder+0.001)*100;
      if(SA.AllowedVolume(lot) < 0) return true;
      if(next_margin_level < StopMarginLevel) {
         Print("Order was canceled: Margin level can't be under StopMarginLevel:", StopMarginLevel, "%" );
         return(true);
      }
      return(false);
   }

 private:
   double ModifiedLot() {
      // double TradeRisk = MathAbs(SL - Ask) * priceToPips;
      //if(TradeRisk == 0) return false;
      if(!isLotModified) return lot;
      SA.Refresh();
      lot = NormalizeDouble(SA.equity / risk, SA.LotDigits);
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
