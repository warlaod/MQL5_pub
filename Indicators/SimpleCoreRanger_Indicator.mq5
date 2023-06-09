//+------------------------------------------------------------------+
//|                                             SimpleCoreRanger_Indicator.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 4
#property indicator_plots   4
//--- plot Highest
#property indicator_label1  "Highest"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
//--- plot Lowest
#property indicator_label2  "Lowest"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrDeepSkyBlue
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2
//--- plot CoreHighest
#property indicator_label3  "CoreHighest"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrFuchsia
#property indicator_style3  STYLE_SOLID
#property indicator_width3  2
//--- plot CoreLowest
#property indicator_label4  "CoreLowest"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrFuchsia
#property indicator_style4  STYLE_SOLID
#property indicator_width4  2
//--- input parameters
input double   coreRange = 0.2;
input int      pricePeriod = 5;
//--- indicator buffers
double         HighestBuffer[];
double         LowestBuffer[];
double         CoreHighestBuffer[];
double         CoreLowestBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
   int barMaxCount = Bars(_Symbol, PERIOD_CURRENT);
   if(pricePeriod > barMaxCount) {
      Alert( StringFormat("please set pricePeriod lower than %i(maximum number of bars for calculations)", barMaxCount));
      return(INIT_PARAMETERS_INCORRECT);
   }
//--- indicator buffers mapping
   SetIndexBuffer(0, HighestBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, LowestBuffer, INDICATOR_DATA);
   SetIndexBuffer(2, CoreHighestBuffer, INDICATOR_DATA);
   SetIndexBuffer(3, CoreLowestBuffer, INDICATOR_DATA);
   IndicatorSetInteger(INDICATOR_DIGITS, Digits());

   return (INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate (const int rates_total,      // 入力時系列のサイズ
                 const int prev_calculated,  // 以前の呼び出しで処理されたバー
                 const datetime& time[],     // 時間
                 const double& open[],       // 始値
                 const double& high[],       // 高値
                 const double& low[],        // 安値
                 const double& close[],      // 終値
                 const long& tick_volume[],  // ティックボリューム
                 const long& volume[],       // ボリューム
                 const int& spread[]         // スプレッド
                ) {

   int start = prev_calculated == 0 ? 0 : prev_calculated - pricePeriod - 1;
   for(int i = start; i < rates_total; i++) {
      if(i - (pricePeriod - 1) < 0) {
         HighestBuffer[i] = EMPTY_VALUE;
         LowestBuffer[i] = EMPTY_VALUE;
         CoreHighestBuffer[i] = EMPTY_VALUE;
         CoreLowestBuffer[i] = EMPTY_VALUE;
         continue;
      };

      double highest = high[ArrayMaximum(high, i - (pricePeriod - 1), pricePeriod)];
      double lowest = low[ArrayMinimum(low, i - (pricePeriod - 1), pricePeriod)];

      double gap = highest - lowest;
      double coreHighest = lowest + (0.5 + coreRange) * gap;
      double coreLowest = lowest + (0.5 - coreRange) * gap;

      HighestBuffer[i] = highest;
      LowestBuffer[i] = lowest;
      CoreHighestBuffer[i] = coreHighest;
      CoreLowestBuffer[i] = coreLowest;
   }
   return(rates_total);
}
//+------------------------------------------------------------------+
