//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#include <ChartObjects\ChartObjectsLines.mqh>
#include <MyPkg\Logger.mqh>

input bool drawLine = false;
class HLine: public CChartObjectHLine  {
 public:
   string symbol;

   void Create(long chartId, string name, color clr,int window, Logger &logger) {
      if(!drawLine) return;
      bool result = CChartObjectHLine::Create(chartId, name, window, 0) &&
                    CChartObjectHLine::Color(clr) &&
                    Style(STYLE_SOLID) &&
                    Width(2);
      if(!result) {
         logger.Log(StringFormat("Failed to create a line on the chart: %s", name), Warning);
      }
   }

   void Draw(double price) {
      if(!drawLine) return;
      this.SetPoint(0,0, price);
   }
};


//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
