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

class LawOfJungle {
 public:
   ENUM_TIMEFRAMES Timeframe;
   string strongest;
   string weakest;
   string symbol;

   void LawOfJungle(string symbol) {
      this.symbol = symbol;
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

 private:
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
