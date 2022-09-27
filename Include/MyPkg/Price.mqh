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

   MqlRates At(string symbol,uchar index) {
      CopyRates(symbol, timefrane, index, 1, price);
      return price[0];
   }

   double Highest(string symbol, int start, int end) {
      CopyHigh(symbol, timefrane, start, end, high);
      return high[ArrayMaximum(high, 0, end)];
   }

   double Lowest(string symbol,int start, int end) {
      CopyLow(symbol, timefrane, start, end, low);
      return low[ArrayMinimum(low, 0, end)];
   }

 private:
   MqlRates price[];
   double high[];
   double low[];
};
//+------------------------------------------------------------------+
