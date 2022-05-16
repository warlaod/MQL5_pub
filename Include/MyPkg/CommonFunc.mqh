//--- Store Common functions


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Ask() {
   return  NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Bid() {
   return NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
}
//+------------------------------------------------------------------+
bool CheckNewBarOpen(ENUM_TIMEFRAMES tf) {
   static datetime time = 0;
   if(iTime(_Symbol, tf, 0) != time) {
      time = iTime(_Symbol, tf, 0);
      return true;
   }
   return false;
}

static datetime lastServerTime;
bool CheckMarketOpen() {
   datetime currentServerTime = TimeCurrent();
   if(currentServerTime != lastServerTime) {
      lastServerTime = currentServerTime;
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CheckEquityThereShold(int thereShold) {
   int equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(equity < thereShold) {
      printf("Equity is lower than thereShold: %d", thereShold);
      return false;
   }
   return true;
}

// convert _Point to pips
int DigitAdjust() {
   int digitsAdjust = 1;
   if(_Digits == 3 || _Digits == 5)
      digitsAdjust = 10;
   return digitsAdjust;
}
//+------------------------------------------------------------------+
