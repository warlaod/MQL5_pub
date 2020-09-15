//+------------------------------------------------------------------+
//|                                                      MyPrice.mqh |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
// #define MacrosHello   "Hello, world!"
// #define MacrosYear    2010
//+------------------------------------------------------------------+
//| DLL imports                                                      |
//+------------------------------------------------------------------+
// #import "user32.dll"
//   int      SendMessageA(int hWnd,int Msg,int wParam,int lParam);
// #import "my_expert.dll"
//   int      ExpertRecalculate(int wParam,int lParam);
// #import
//+------------------------------------------------------------------+
//| EX5 imports                                                      |
//+------------------------------------------------------------------+
// #import "stdlib.ex5"
//   string ErrorDescription(int error_code);
// #import
//+------------------------------------------------------------------+
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
   
   void Refresh(){
      CopyRates(_Symbol, Timeframe, 0, count, price);
   }

   MqlRates getData(int index) {
      return price[index];
   }

   double Higest() {
      CopyHigh(_Symbol, Timeframe, 0, count, High);
      if(ArraySize(High) < count) CopyHigh(_Symbol, Period(), 0, count, High);
      return price[ArrayMaximum(High, 0, count)].high;
   }

   double Lowest() {
      CopyLow(_Symbol, Timeframe, 0, count, Low);
      if(ArraySize(Low) < count) CopyLow(_Symbol, Period(), 0, count, Low);
      return price[ArrayMinimum(Low, 0, count)].low;
   }
   
   double RosokuHigh(int index) {
      if(RosokuDirection(index)) return  price[index].high - price[index].close;
      return  price[index].high - price[index].open;
   }
   
   double RosokuLow(int index) {
      if(RosokuDirection(index)) return  price[index].open - price[index].low;
      return  price[index].close - price[index].low;
   }
   
   double RosokuBody(int index){
      return MathAbs( price[index].close - price[index].open );
   }
   
   double RosokuDirection(int index) {
      bool PlusDirection = price[index].close > price[index].open ? true : false;
      return PlusDirection;
   }

 private:
   MqlRates price[];
    double High[];
    double Low[];
};
//+------------------------------------------------------------------+
