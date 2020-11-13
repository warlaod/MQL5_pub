//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

#include <Original\MyCalculate.mqh>

input int spread = -1;
input int denom = 30000;
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

  void MyTrade(int LotDigits = -1) {
    minlot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
    maxlot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
    if(LotDigits != -1) {
      this.LotDigits = LotDigits;
      ModifyLot();
      return;
    }
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

  void CheckSpread() {
    int currentSpread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
    if(spread == -1)
      return;
    if(currentSpread >= spread)
      istradable = false;
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

  

  void CheckBalance() {
    if(NormalizeDouble(AccountInfoDouble(ACCOUNT_BALANCE), 1) < StopBalance) {
      istradable = false;
    }
  }

  void CheckMarginLevel() {
    double marginlevel = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
    if(marginlevel < StopMarginLevel && marginlevel != 0 ) istradable = false;
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
