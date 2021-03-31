//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
class MyPrice {
 public:
   ENUM_TIMEFRAMES Timeframe;
   void MyPrice(ENUM_TIMEFRAMES Timeframe) {
      this.Timeframe = Timeframe;
      ArraySetAsSeries(price, true);
      ArraySetAsSeries(Low, true);
      ArraySetAsSeries(High, true);
   }

   void Refresh(int count) {
      CopyRates(_Symbol, Timeframe, 0, count, price);
   }

   MqlRates At(int index) {
      return price[index];
   }

   double Highest(int start, int high_count) {
      CopyHigh(_Symbol, Timeframe, start, high_count, High);
      return High[ArrayMaximum(High, 0, high_count)];
   }

   double Lowest(int start, int low_count) {
      CopyLow(_Symbol, Timeframe, start, low_count, Low);
      return Low[ArrayMinimum(Low, 0, low_count)];
   }

   double RosokuHighLength(int index) {
      double higher = price[index].close < price[index].open ? price[index].open : price[index].close;
      return  price[index].high - higher;
   }

   double RosokuLowLength(int index) {
      double lower = price[index].close > price[index].open ? price[index].open : price[index].close;
      return  lower - price[index].low;
   }

   double RosokuBodyLength(int index) {
      return MathAbs( price[index].close - price[index].open );
   }

   double RosokuPerB(int index) {
      return (price[index].close - price[index].low) / (price[index].high - price[index].low);
   }

   bool RosokuIsPlus(int index) {
      bool PlusDirection = price[index].close > price[index].open ? true : false;
      return PlusDirection;
   }

 private:
   MqlRates price[];
   double High[];
   double Low[];
};
//+------------------------------------------------------------------+
