//+------------------------------------------------------------------+
//|                                                      MyChart.mqh |
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
class MyChart {
 public:
   bool Channel(int Lowest_Start_Time, double Lowest_Val, double Highest_Start_Time, double Highest_Val) {
      string ChartName = "MyChannel";
      ObjectDelete(_Symbol, ChartName);
      ObjectCreate(_Symbol, ChartName, OBJ_CHANNEL, Lowest_Start_Time, Lowest_Val, Highest_Start_Time, Highest_Val);
      ObjectSetInteger(0, ChartName, OBJPROP_COLOR, clrYellow);
      ObjectSetInteger(0, ChartName, OBJPROP_RAY_RIGHT, true);
      return true;
   }

   bool HLine(int Start_Time, double Val, string ChartName = "MyHLine") {
      string chartName = ChartName;
      ObjectDelete(_Symbol, chartName);
      ObjectCreate(_Symbol, chartName, OBJ_HLINE, 0, Start_Time, Val);
      ObjectSetInteger(0, chartName, OBJPROP_COLOR, clrYellow);
      ObjectSetInteger(0, chartName, OBJPROP_RAY_RIGHT, true);
      return true;
   }

};
//+------------------------------------------------------------------+
