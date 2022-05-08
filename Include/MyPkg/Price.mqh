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

   MqlRates At(uchar index) {
      CopyRates(_Symbol, timefrane, index, index + 1, price);
      return price[index];
   }

   double Highest(uchar start, uchar end) {
      CopyHigh(_Symbol, timefrane, start, end, high);
      return high[ArrayMaximum(high, 0, end)];
   }

   double Lowest(uchar start, uchar end) {
      CopyLow(_Symbol, timefrane, start, end, low);
      return low[ArrayMinimum(low, 0, end)];
   }

   double Ask() {
      return  NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   }

   double Bid() {
      return NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   }

 private:
   MqlRates price[];
   double high[];
   double low[];
};
//+------------------------------------------------------------------+
