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
      if(BearTrend("USDJPY") && BearTrend("EURJPY") && BearTrend("GBPJPY") && BearTrend("AUDJPY")) return true;
      return false;
   }
   bool isJPYWeakest() {
      if(BullTrend("USDJPY") && BullTrend("EURJPY") && BullTrend("GBPJPY") && BullTrend("AUDJPY")) return true;
      return false;
   }

   bool isUSDStrongest() {
      if(BullTrend("USDJPY") && BearTrend("EURUSD") && BearTrend("GBPUSD") && BearTrend("AUDUSD")) return true;
      return false;
   }
   bool isUSDWeakest() {
      if(BearTrend("USDJPY") && BullTrend("EURUSD") && BullTrend("GBPUSD") && BullTrend("AUDUSD")) return true;
      return false;
   }

   bool isGBPStrongest() {
      if(BullTrend("GBPJPY") && BullTrend("GBPUSD") && BullTrend("GBPAUD") && BearTrend("EURGBP")) return true;
      return false;
   }
   bool isGBPWeakest() {
      if(BearTrend("GBPJPY") && BearTrend("GBPUSD") && BearTrend("GBPAUD") && BullTrend("EURGBP")) return true;
      return false;
   }

   bool isAUDStrongest() {
      if(BullTrend("AUDJPY") && BullTrend("AUDUSD") && BearTrend("EURAUD") && BearTrend("GBPAUD")) return true;
      return false;
   }
   bool isAUDWeakest() {
      if(BearTrend("AUDJPY") && BearTrend("AUDUSD") && BullTrend("EURAUD") && BullTrend("GBPAUD")) return true;
      return false;
   }

   bool isEURStrongest() {
      if(BullTrend("EURJPY") && BullTrend("EURUSD") && BullTrend("EURGBP") && BullTrend("EURAUD")) return true;
      return false;
   }
   bool isEURWeakest() {
      if(BearTrend("EURJPY") && BearTrend("EURUSD") && BearTrend("EURGBP") && BearTrend("EURAUD")) return true;
      return false;
   }

   ENUM_ORDER_TYPE Trend() {
      string front = StringSubstr(symbol, 0, 3);
      string back = StringSubstr(symbol, 3, 3);
      strongest =  StrongestCurrency();
      weakest = WeakestCurrency();
      if(front == strongest && back == weakest)
         return ORDER_TYPE_BUY;
      if(back == strongest && front == weakest)
         return ORDER_TYPE_SELL;
      return NULL;
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

   ENUM_ORDER_TYPE CurrencyTrend(string symb) {
      CopyRates(symb, Timeframe, 1, 3, price);
      if(price[2].low < price[1].low && price[2].high < price[1].high) {
         return ORDER_TYPE_BUY;
      } else if(price[2].low > price[1].low && price[2].high > price[1].high)
         return ORDER_TYPE_SELL;
      return NULL;
   }
   bool BullTrend(string symb) {
      if(CurrencyTrend(symb) == ORDER_TYPE_BUY) return true;
      return false;
   }
   bool BearTrend(string symb) {
      if(CurrencyTrend(symb) == ORDER_TYPE_SELL) return true;
      return false;
   }
};
//+------------------------------------------------------------------+
