
class MyPrice {
 public:
   int count ;
   ENUM_TIMEFRAMES Timeframe;
   void MyPrice(ENUM_TIMEFRAMES Timeframe, int count) {
      this.Timeframe = Timeframe;
      this.count = count;
      ArraySetAsSeries(price, true);
      ArraySetAsSeries(Low, true);
      ArraySetAsSeries(High, true);
   }

   void Refresh() {
      CopyRates(_Symbol, Timeframe, 0, count, price);
      if(ArraySize(price) < count) {
         CopyRates(_Symbol, _Period, 0, count, price);
         Comment("Warning: Now using current Timeframe due to shortage of bars");
      }
   }

   MqlRates At(int index) {
      return price[index];
   }

   double Highest(int start,int high_count) {
      CopyHigh(_Symbol, Timeframe, start, high_count, High);
      
      return High[ArrayMaximum(High,0,high_count)];
   }

   double Lowest(int start,int low_count) {
      CopyLow(_Symbol, Timeframe, start, low_count, Low);

      return Low[ArrayMinimum(Low, 0, low_count)];
   }

   double RosokuHigh(int index) {
      double higher = price[index].close < price[index].open ? price[index].open : price[index].close;
      return  price[index].high - higher;
   }

   double RosokuLow(int index) {
      double lower = price[index].close > price[index].open ? price[index].open : price[index].close;
      return  lower - price[index].low;
   }

   double RosokuBody(int index) {
      return MathAbs( price[index].close - price[index].open );
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
