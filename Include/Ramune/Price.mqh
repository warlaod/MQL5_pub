//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#include <Ramune\Logger.mqh>

class Price {
 public:
   ENUM_TIMEFRAMES timefrane;
   void Price(ENUM_TIMEFRAMES timefrane) {
      this.timefrane = timefrane;
      ArraySetAsSeries(price, true);
      ArraySetAsSeries(low, true);
      ArraySetAsSeries(high, true);
   }

   MqlRates At(string symbol, uchar index) {
      CopyRates(symbol, timefrane, index, 1, price);
      return price[0];
   }

   double Highest(string symbol, int start, int end, Logger &logger) {
      if(!CopyHigh(symbol, timefrane, start, end, high)) {
         logger.Log("Couldn't copy price.high",Error);
         return EMPTY_VALUE;
      }
      int size = ArraySize(high);
      if( size < end) {
         logger.Log(StringFormat("Couldn't get highest value: scanned candles: %i, you required: %i", size, end),Error);
         return EMPTY_VALUE;
      }
      int max = ArrayMaximum(high, 0, end);
      return high[ArrayMaximum(high, 0, end)];
   }

   double Lowest(string symbol, int start, int end, Logger &logger) {
      if(!CopyLow(symbol, timefrane, start, end, low)) {
         logger.Log("Couldn't copy price.high",Error);
         return EMPTY_VALUE;
      }
      int size = ArraySize(high);
      if( size < end) {
         logger.Log(StringFormat("Couldn't get highest value: scanned candles: %i, you required: %i", size, end),Error);
         return EMPTY_VALUE;
      }

      return low[ArrayMinimum(low, 0, end)];
   }

 private:
   MqlRates price[];
   double high[];
   double low[];
};
//+------------------------------------------------------------------+
