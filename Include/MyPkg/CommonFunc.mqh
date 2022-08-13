//--- Store Common functions


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Ask(string symbol) {
   return  NormalizeDouble(SymbolInfoDouble(symbol, SYMBOL_ASK), _Digits);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Bid(string symbol) {
   return NormalizeDouble(SymbolInfoDouble(symbol, SYMBOL_BID), _Digits);
}
//+------------------------------------------------------------------+
bool CheckNewBarOpen(ENUM_TIMEFRAMES tf, string symbol) {
   static datetime time = 0;
   if(iTime(symbol, tf, 0) != time) {
      time = iTime(symbol, tf, 0);
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
int DigitAdjust(string symbol) {
   int digitsAdjust = 1;
   int digit = SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   if(digit == 3 || digit == 5)
      digitsAdjust = 10;
   return digitsAdjust;
}

// convert numeric to Pips;
double Pips(string symbol) {
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   return point * DigitAdjust(symbol);
}

double Spread(string symbol) {
   return SymbolInfoInteger(symbol, SYMBOL_SPREAD)* SymbolInfoDouble(symbol, SYMBOL_POINT);
}