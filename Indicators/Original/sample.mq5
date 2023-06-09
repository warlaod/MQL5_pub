//+------------------------------------------------------------------+
//|                                                    BandWidth.mq5 |
//|                                 Copyright 2020, Beleif Co., Ltd. |
//|                                           https://belief-hf.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Beleif Co., Ltd."
#property link      "https://belief-hf.com/"
//#property version   "1.00"
#property indicator_separate_window

#property indicator_buffers 4
#property indicator_plots 1

#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDeepPink
#property indicator_width1  2

input int     BandsPeriod=20;       // ボリンジャーバンド期間
input int     BandsShift=0;         // シフト
input double  BandsDeviations=2.0;  // 偏差

double IndBuffer[];
double BB_MLBuffer[];
double BB_TLBuffer[];
double BB_BLBuffer[];

int hBB;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,IndBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,BB_MLBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(2,BB_TLBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,BB_BLBuffer,INDICATOR_CALCULATIONS);

   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,BandsPeriod-1);

   PlotIndexSetString(0,PLOT_LABEL,"BandWidth("+string(BandsPeriod)+",Dev"+string(BandsDeviations)+")");

   string short_name="BandWidth("+string(BandsPeriod)+","+(string)(BandsDeviations)+")";
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);

   hBB=iBands(NULL,0,BandsPeriod,BandsShift,BandsDeviations,PRICE_CLOSE);
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
                const int &spread[])
  {
//---
   if(BarsCalculated(hBB)<rates_total)
      return(0);

   int to_copy;
   to_copy=rates_total-prev_calculated;
   if(to_copy==0)
      to_copy++;

   if(CopyBuffer(hBB,0,0,to_copy,BB_MLBuffer)<=0)
      return(0);
   if(CopyBuffer(hBB,1,0,to_copy,BB_TLBuffer)<=0)
      return(0);
   if(CopyBuffer(hBB,2,0,to_copy,BB_BLBuffer)<=0)
      return (0);

   int limit;
   if(prev_calculated==0)
      limit=0;
   else limit=prev_calculated-1;

   for(int i=limit;i<rates_total && !IsStopped();i++)
     {
      if(BB_MLBuffer[i])
         IndBuffer[i]=(BB_TLBuffer[i]-BB_BLBuffer[i])/BB_MLBuffer[i];
      else
         IndBuffer[i]=0;
     }

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//|ハンドルの開放                                                         |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   IndicatorRelease(hBB);
  }
//+------------------------------------------------------------------+