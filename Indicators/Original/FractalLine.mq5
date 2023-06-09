//+------------------------------------------------------------------+
//|                                                  FractalLine.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#include <Math\Stat\Normal.mqh>

#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 8
#property indicator_plots   6
//--- plot ShortUpper
#property indicator_label1  "ShortUpper"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot ShortLower
#property indicator_label2  "ShortLower"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- plot ShortUpper
#property indicator_label1  "MiddleUpper"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrYellowGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot ShortLower
#property indicator_label2  "MiddleLower"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrYellowGreen
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- plot ShortUpper
#property indicator_label1  "LongUpper"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrAliceBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot ShortLower
#property indicator_label2  "LongLower"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrAliceBlue
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1

//--- indicator buffers
double         upperBuffer[];
double         lowerBuffer[];

double         shortUpperLine[];
double         shortLowerLine[];

double         middleUpperLine[];
double         middleLowerLine[];

double         longUpperLine[];
double         longLowerLine[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
input string symbol;
input ENUM_TIMEFRAMES tf;

int fractal;
int OnInit() {
//--- indicator buffers mapping

   SetIndexBuffer(0, shortUpperLine, INDICATOR_DATA);
   SetIndexBuffer(1, shortLowerLine, INDICATOR_DATA);
   SetIndexBuffer(2, middleUpperLine, INDICATOR_DATA);
   SetIndexBuffer(3, middleLowerLine, INDICATOR_DATA);
   SetIndexBuffer(4, longUpperLine, INDICATOR_DATA);
   SetIndexBuffer(5, longLowerLine, INDICATOR_DATA);
   SetIndexBuffer(6, upperBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(7, lowerBuffer, INDICATOR_CALCULATIONS);


   fractal = iFractals(NULL, PERIOD_CURRENT);

//---
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]) {
//---
   if(BarsCalculated(fractal) < rates_total)
      return(0);


   int to_copy;
   to_copy = rates_total - prev_calculated;
   if(to_copy == 0)
      to_copy++;

   if(CopyBuffer(fractal, 0, 0, to_copy, upperBuffer) <= 0)
      return(0);

   if(CopyBuffer(fractal, 1, 0, to_copy, lowerBuffer) <= 0)
      return(0);

   int limit;
   if( prev_calculated == 0)
      limit = 0;
   else
      limit = prev_calculated - 1;


   for(int i = limit; i < rates_total && !IsStopped(); i++) {
      if(upperBuffer[i] != EMPTY_VALUE) {
         shortUpperLine[i] = upperBuffer[i];
      } else if(i > 1) {
         shortUpperLine[i] = shortUpperLine[i - 1];
      }

      if(lowerBuffer[i] != EMPTY_VALUE) {
         shortLowerLine[i] = lowerBuffer[i];
      } else if(i > 1 && shortLowerLine[i - 1]) {
         shortLowerLine[i] = shortLowerLine[i - 1];
      }
   }

   double uniqShortUpperLine[];
   MathUnique(shortUpperLine, uniqShortUpperLine);

   for(int i = ArraySize(uniqShortUpperLine); i < 0; i--) {
      
   }

//--- return value of prev_calculated for next call
   return(rates_total);
}
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   IndicatorRelease(fractal);
}
//+------------------------------------------------------------------+
