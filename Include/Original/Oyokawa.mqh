//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

#include <Original\MyCalculate.mqh>
#include <Indicators\Trend.mqh>

class CurrencyStrength {
 public:
   string strongest;
   string weakest;
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

   bool isStrongest(string currency){
   
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
      CiMA ciMA;
      ciMA.Create(_Symbol,Timeframe,5,0,MODE_EMA,PRICE_CLOSE);
      double Trend = ciMA.Main(0) - ciMA.Main(5);
      if(Trend > 0) return true;
      return false;
   }



};
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
