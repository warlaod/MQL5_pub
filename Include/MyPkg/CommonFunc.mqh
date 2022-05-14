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
bool isNewBarOpened(ENUM_TIMEFRAMES tf) {
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
