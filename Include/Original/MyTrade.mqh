
input int spread = 99999;
input int denom = 30000;
input int positions = 2;
input bool isLotModified = false;
input int FridayEndHour = 23;
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

   void MyTrade() {
      minlot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
      maxlot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
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
      TimeToStruct(TimeCurrent(), dt);
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
         if((dt.hour == FridayEndHour && dt.min > 0) || dt.hour >= FridayEndHour) {
            istradable = false;
         }
      }
   }

   void CheckBalance() {
      if(NormalizeDouble(AccountInfoDouble(ACCOUNT_BALANCE), 1) < StopBalance) {
         istradable = false;
      }
   }

   void CheckUntradableHour(int &hours[]) {
      for(int i = 0; i < ArraySize(hours); i++) {
         if(dt.hour == hours[i]) {
            istradable = false;
            return;
         }
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
