//--- Store Common functions
#include <Ramune\Logger.mqh>

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
bool CheckEquity(int thereShold, Logger &logger) {
   if(thereShold == 0) return true;
   int equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(equity < thereShold) {
      logger.Log(StringFormat("Trading was stopped :: Equity(current: %d) is lower than stopEquity(%d)", equity, thereShold),Warning);
      return false;
   }
   return true;
}

bool CheckMarginLevel(int thereShold, Logger &logger) {
   double marginLevel = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
   if(thereShold == 0 || marginLevel == 0) return true;
   
   if(marginLevel < thereShold) {
      logger.Log(StringFormat("Trading was stopped :: MarginLevel(current: %.2f) is lower than stopMarginLevel(%d)",marginLevel, thereShold),Warning);
      return false;
   }
   return true;
}

bool CheckDrawDownPer(int thereShold, Logger &logger) {
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double drawDownPer = (balance - equity) / balance * 100;
   
   if(balance == 0 || equity == 0 || thereShold == 0 || drawDownPer == 0){
      return true;
   }
   
   if(drawDownPer > thereShold) {
      logger.Log(StringFormat("Trading was stopped :: DrawDown(current: %.2f) is over than stopDrawDownPer(%d)", drawDownPer, thereShold),Warning);
      return false;
   }
   return true;
}

bool IsBetween(double target, double bottom, double top){
   if(target >= bottom && target <= top){
      return true;
   }
   return false;
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

bool CheckSpread(string symbol, int thereShold){
   if(thereShold == 0) return true;
   double spread = Spread(symbol);
   if(spread > thereShold*Pips(symbol)){
      return false;
   }
   return true;
}