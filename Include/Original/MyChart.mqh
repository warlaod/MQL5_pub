//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

class MyChart {
 public:
   bool Channel(int Lowest_Start_Time, double Lowest_Val, double Highest_Start_Time, double Highest_Val) {
      string ChartName = "MyChannel";
      ObjectDelete(_Symbol, ChartName);
      ObjectCreate(_Symbol, ChartName, OBJ_CHANNEL, Lowest_Start_Time, Lowest_Val, Highest_Start_Time, Highest_Val);
      ObjectSetInteger(0, ChartName, OBJPROP_COLOR, clrYellow);
      return true;
   }

   bool HLine(double Val, datetime Start_Time = 0, string ChartName = "MyHLine", long Clr =  clrYellow) {
      ObjectDelete(_Symbol, ChartName);
      ObjectCreate(_Symbol, ChartName, OBJ_HLINE, 0, Start_Time, Val);
      ObjectSetInteger(0, ChartName, OBJPROP_COLOR, Clr);
      return true;
   }

   bool HalfLine(double Val, datetime Start_Time = 0, string ChartName = "MyHLine", long Clr =  clrYellow) {
      ObjectDelete(_Symbol, ChartName);
      ObjectCreate(_Symbol, ChartName, OBJ_TREND, 0, Start_Time, Val, TimeCurrent(), Val);
      ObjectSetInteger(0, ChartName, OBJPROP_COLOR, Clr);
      return true;
   }
};
//+------------------------------------------------------------------+
