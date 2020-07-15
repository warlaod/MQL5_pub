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
input const ENUM_TIMEFRAMES PriceTimeframe;
class MyPrice {
 public:
   void MyPrice() {
      ArraySetAsSeries(price, true);
   }

   MqlRates getData(int index, ENUM_TIMEFRAMES Timeframe) {
      CopyRates(_Symbol, Timeframe, 0, index, price);
      return price[index];
   }

   double Higest(ENUM_TIMEFRAMES Timeframe, int count) {
      CopyRates(_Symbol, Timeframe, 0, count, price);

      double High[];
      ArraySetAsSeries(High, true);

      CopyHigh(_Symbol, Timeframe, 0, count, High);
      if(!High[count - 1]) {
         return NULL;
      }

      return price[ArrayMaximum(High, 0, count)].high;
   }

   double Lowest(ENUM_TIMEFRAMES Timeframe, int count) {
      CopyRates(_Symbol, Timeframe, 0, count, price);

      double Low[];
      ArraySetAsSeries(Low, true);

      CopyLow(_Symbol, Timeframe, 0, count, Low);
      if(!Low[count - 1]) {
         return NULL;
      }

      return price[ArrayMinimum(Low, 0, count)].low;
   }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+


 private:
   MqlRates price[];


};
//+------------------------------------------------------------------+
