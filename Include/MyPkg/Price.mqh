//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
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

   double Highest(string symbol, int start, int end) {
      if(!CopyHigh(symbol, timefrane, start, end, high)) {
         printf("Error: Couldn't copy price.high");
         return EMPTY_VALUE;
      }
      int size = ArraySize(high);
      if( size < end ) {
         printf("Error: Couldn't get highest value: candles: %i, you required: %i", size, end);
         return EMPTY_VALUE;
      }
      int max = ArrayMaximum(high, 0, end);
      return high[ArrayMaximum(high, 0, end)];
   }

   double Lowest(string symbol, int start, int end) {
      if(!CopyLow(symbol, timefrane, start, end, low)) {
         printf("Error: Couldn't copy price.high");
         return EMPTY_VALUE;
      }
      int size = ArraySize(high);
      if( size < end ) {
         printf("Error: Couldn't get highest value: candles: %i, you required: %i", size, end);
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
