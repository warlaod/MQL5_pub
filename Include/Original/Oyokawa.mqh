//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

#include <Original\MyCalculate.mqh>
#include <Indicators\Trend.mqh>
#include <Indicators\TimeSeries.mqh>
#include <Indicators\Oscilators.mqh>
#include <Original\MyPrice.mqh>

class CurrencyStrength {
 public:
   ENUM_TIMEFRAMES Timeframe;
   string strongest;
   string weakest;
   string symbol;

   void CurrencyStrength(ENUM_TIMEFRAMES Timeframe, string symbol) {
      this.Timeframe = Timeframe;
      this.symbol = symbol;
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
      if(!isRising("EURJPY") && !isRising("EURUSD") && !isRising("EURGBP") && isRising("EURAUD")) return true;
      return false;
   }

   string Trend() {
      string front = StringSubstr(symbol, 0, 3);
      string back = StringSubstr(symbol, 3, 3);
      strongest =  StrongestCurrency();
      weakest = WeakestCurrency();
      if(front == strongest && back == weakest)
         return "bear";
      if(back == strongest && back == weakest)
         return "bull";
      return "";
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

   bool isRising(string symbol) {
      CopyRates(symbol, Timeframe, 1, 2, price);
      if(price[2].low < price[1].low && price[2].close < price[1].close) {
         return true;
      }
      return false;
   }
};
