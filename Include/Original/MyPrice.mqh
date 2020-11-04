
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

   double Higest(int start,int high_count) {
      CopyHigh(_Symbol, Timeframe, start, high_count, High);
      if(ArraySize(High) < high_count) {
         CopyHigh(_Symbol, _Period, 0, high_count, High);
         Comment("Warning: Now using current Timeframe due to shortage of bars");
      }
      return High[ArrayMaximum(High,0,high_count)];
   }

   double Lowest(int start,int low_count) {
      CopyLow(_Symbol, Timeframe, start, low_count, Low);
      if(ArraySize(Low) < low_count) {
         CopyLow(_Symbol, _Period, 0, low_count, Low);
         Comment("Warning: Now using current Timeframe due to shortage of bars");
      }
      return Low[ArrayMinimum(Low, 0, low_count)];
   }

   double RosokuHigh(int index) {
      if(RosokuIsPlus(index)) return  price[index].high - price[index].close;
      return  price[index].high - price[index].open;
   }

   double RosokuLow(int index) {
      if(RosokuIsPlus(index)) return  price[index].open - price[index].low;
      return  price[index].close - price[index].low;
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
