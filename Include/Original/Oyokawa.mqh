//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

#include <Original\MyCalculate.mqh>


class CurrencyStrength {
 public:
   void CurrencyStrength(ENUM_TIMEFRAMES Timeframe, int count) {
      this.Timeframe = Timeframe;
      this.count = count;
      ArraySetAsSeries(price, true);
   }



   bool isJPYStrongest() {
      if(!isRising("USDJPY") && !isRising("EURJPY") && !isRising("GBPJPY") && !isRising("AUDJPY")) return true;
      return false;
   }
   bool isJPYWeakest() {
      if(isRising("USDJPY") && isRising("EURJPY") && isRising("GBPJPY") && isRising("AUDJPY")) return true;
      return false;
   }

   bool isUSDStrongest() {
      if(isRising("USDJPY") && !isRising("EURUSD") && !isRising("GBPUSD") && !isRising("AUDUSD")) return true;
      return false;
   }
   bool isUSDWeakest() {
      if(!isRising("USDJPY") && isRising("EURUSD") && isRising("GBPUSD") && isRising("AUDUSD")) return true;
      return false;
   }

   bool isGBPStrongest() {
      if(isRising("GBPJPY") && isRising("GBPUSD") && isRising("GBPAUD") && !isRising("EURGBP")) return true;
      return false;
   }
   bool isGBPWeakest() {
      if(!isRising("GBPJPY") && !isRising("GBPUSD") && !isRising("GBPAUD") && isRising("EURGBP")) return true;
      return false;
   }

   bool isAUDStrongest() {
      if(isRising("AUDJPY") && isRising("AUDUSD") && !isRising("EURAUD") && !isRising("GBPAUD")) return true;
      return false;
   }
   bool isAUDWeakest() {
      if(!isRising("AUDJPY") && !isRising("AUDUSD") && isRising("EURAUD") && isRising("GBPAUD")) return true;
      return false;
   }

   bool isEURStrongest() {
      if(isRising("EURJPY") && isRising("EURUSD") && isRising("EURGBP") && !isRising("EURAUD")) return true;
      return false;
   }
   bool isEURWeakest() {
      if(!isRising("EURJPY") && !isRising("EURUSD") && !isRising("EURGBP") && !isRising("EURAUD")) return true;
      return false;
   }



   string StrongestCurrency() {
      if(isAUDStrongest()) return "AUD";
      if(isEURStrongest()) return "EUR";
      if(isJPYStrongest()) return "JPY";
      if(isGBPStrongest()) return "GBP";
      if(isUSDStrongest()) return "USD";
      return "";
   }

   string WeakestCurrency() {
      if(isAUDWeakest()) return "AUD";
      if(isEURWeakest()) return "EUR";
      if(isJPYWeakest()) return "JPY";
      if(isGBPWeakest()) return "GBP";
      if(isUSDWeakest()) return "USD";
      return "";
   }

 private:
   MqlRates price[];
   int count ;
   ENUM_TIMEFRAMES Timeframe;

   bool isRising(string symbol) {
      CopyRates(symbol, Timeframe, 0, count, price);
      if(price[0].open < price[0].close) return true;
      return false;
   }



};
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
