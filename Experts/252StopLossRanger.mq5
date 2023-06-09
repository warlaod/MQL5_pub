//+------------------------------------------------------------------+
//|                                            1009ScalpFractals.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
#include <Original\MyUtils.mqh>
#include <Original\MyTrade.mqh>
#include <Original\Oyokawa.mqh>
#include <Original\MyDate.mqh>
#include <Original\MyCalculate.mqh>
#include <Original\MyTest.mqh>
#include <Original\MyPrice.mqh>
#include <Original\MyPosition.mqh>
#include <Original\MyOrder.mqh>
#include <Original\MyCHart.mqh>
#include <Original\MyFractal.mqh>
#include <Original\Optimization.mqh>
#include <Indicators\TimeSeries.mqh>
#include <Indicators\Oscilators.mqh>
#include <Indicators\Trend.mqh>
#include <Indicators\BillWilliams.mqh>
#include <Indicators\Volumes.mqh>
#include <Trade\PositionInfo.mqh>
#include <ChartObjects\ChartObjectsLines.mqh>

input double SLCoef, TPCoef;
input mis_MarcosTMP timeFrame, bandTimeframe;
ENUM_TIMEFRAMES Timeframe = defMarcoTiempo(timeFrame);
ENUM_TIMEFRAMES BandTimeframe = defMarcoTiempo(bandTimeframe);
bool tradable = false;
double PriceToPips = PriceToPips();
double pips = ToPips();

input double CornerCri;
input int PriceCount;
input int SLCorner, OsmaCri, RangeUnitCri;
input double SLCore, CornerPriceCri, RangePriceCri;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyTrade myTrade();
MyDate myDate();
MyPrice myPrice(PERIOD_MN1, 3);
MyOrder myOrder(Timeframe);
CurrencyStrength CS(Timeframe, 1);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CiOsMA ciOsma;
CiBands ciBand;
int OnInit() {
   MyUtils myutils(60 * 1);
   myutils.Init();
   ciOsma.Create(_Symbol, Timeframe, 12, 26, 9, PRICE_TYPICAL);
   ciBand.Create(_Symbol, BandTimeframe, 20, 0, 2, PRICE_TYPICAL);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer() {
   myPrice.Refresh();
   myPosition.Refresh();
   myTrade.Refresh();
   ciOsma.Refresh();
   ciBand.Refresh();

   double lowest_price = myPrice.Lowest(0, PriceCount);
   double highest_price = myPrice.Highest(0, PriceCount);
   double highest_lowest_range = highest_price - lowest_price;
   double current_price = myPrice.At(0).close;

   double bottom, top;
   double range_unit;

   if(MathAbs(ciOsma.Main(1)) > MathAbs(ciOsma.Main(0))) return;
   if(MathAbs(ciOsma.Main(0)) < OsmaCri * pips) return;

   if(current_price < lowest_price + highest_lowest_range * CornerCri) {
      range_unit = MathAbs((ciBand.Upper(0) - ciBand.Lower(0)) / 2) * CornerPriceCri;
      bottom = lowest_price - SLCorner * pips;

      if(range_unit < RangeUnitCri * pips) return;

      if(myPosition.isPositionInRange(POSITION_TYPE_BUY, range_unit)) return;
      if(ciOsma.Main(0) < 0) return;
      myTrade.ForceBuy(bottom, myTrade.Ask + range_unit);
   }


   else if(current_price > highest_price - highest_lowest_range * CornerCri) {
      range_unit = MathAbs((ciBand.Upper(0) - ciBand.Lower(0)) / 2) * CornerPriceCri;
      top = highest_price + SLCorner * pips;

      if(range_unit < RangeUnitCri * pips) return;

      if(myPosition.isPositionInRange(POSITION_TYPE_SELL, range_unit)) return;
      if(ciOsma.Main(0) > 0) return;
      myTrade.ForceSell(top, myTrade.Bid - range_unit);
   }

   else if(current_price > lowest_price + highest_lowest_range * CornerCri && current_price < highest_price - highest_lowest_range * CornerCri) {
      range_unit = MathAbs((ciBand.Upper(0) - ciBand.Lower(0)) / 2) * RangePriceCri;
      top = highest_price - highest_lowest_range * CornerCri + SLCore * highest_lowest_range;
      bottom = lowest_price + highest_lowest_range * CornerCri - SLCore * highest_lowest_range;

      if(range_unit < RangeUnitCri * pips) return;

      if(ciOsma.Main(0) > 0) {
         if(myPosition.isPositionInRange(POSITION_TYPE_BUY, range_unit)) return;
         myTrade.ForceBuy(bottom, myTrade.Ask + range_unit);
      }

      else if(ciOsma.Main(0) < 0) {
         if(myPosition.isPositionInRange(POSITION_TYPE_SELL, range_unit)) return;
         myTrade.ForceSell(top, myTrade.Bid - range_unit);
      }
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
double OnTester() {
   MyTest myTest;
   double result =  myTest.min_dd_and_mathsqrt_trades();
   return  result;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Refresh() {
   myPosition.Refresh();
   myTrade.Refresh();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
