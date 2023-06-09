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
#include <Trade\Trade.mqh>
#include <Original\prices.mqh>
#include <Original\positions.mqh>
#include <Original\period.mqh>
#include <Original\account.mqh>
#include <Original\caluculate.mqh>
#include <Original\MyUtils.mqh>
#include <Original\MyTrade.mqh>
#include <Original\MyCalculate.mqh>
#include <Original\MyTest.mqh>
#include <Original\MyPrice.mqh>
#include <Original\MyPosition.mqh>
#include <Indicators\TimeSeries.mqh>
#include <Indicators\Oscilators.mqh>
#include <Indicators\Trend.mqh>
#include <Trade\OrderInfo.mqh>
CiOsMA ciOsma;
CiATR ciATR;
COrderInfo cOrderInfo;
CTrade trade;
CiBands ciBand;

input ENUM_TIMEFRAMES OsmaTimeframe;
input ENUM_APPLIED_PRICE OsmaAppliedPrice;

input double CornerCri;
input int CornerPriceCri,CorePriceCri;

input int PriceCount;
input int SLCorner,OsmaCri;
input double SLCore;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPrice myPrice(PriceTimeframe, PriceCount);
MyPosition myPosition;
MyTrade myTrade(0.01, true);

// ATR, bottom,top個別
int OnInit() {
   MyUtils myutils(13308, 60 );
   myutils.Init();
   ciOsma.Create(_Symbol, OsmaTimeframe, 12, 25, 9, OsmaAppliedPrice);
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
   
  

   double lowest_price = myPrice.Lowest();
   double highest_price = myPrice.Higest();
   double highest_lowest_range = highest_price - lowest_price;
   double current_price = myPrice.getData(0).close;

   double bottom, top;
   double range_unit;
   
   if(MathAbs(ciOsma.Main(1)) > MathAbs(ciOsma.Main(0))) return;
   if(MathAbs(ciOsma.Main(0)) < OsmaCri*_Point) return;

   if(current_price < lowest_price + highest_lowest_range * CornerCri) {
      range_unit = CornerPriceCri*_Point;
      bottom = lowest_price - SLCorner * _Point;
      
      if(myPosition.isPositionInRange(range_unit, current_price, POSITION_TYPE_BUY)) return;
      if(myTrade.isInvalidTrade(bottom, myTrade.Ask + range_unit)) return;
      if(ciOsma.Main(0) < 0) return;
      trade.Buy(myTrade.lot, NULL, myTrade.Ask, bottom, myTrade.Ask + range_unit, NULL);
   }


   else if(current_price > highest_price - highest_lowest_range * CornerCri) {
      range_unit = CornerPriceCri*_Point;
      top = highest_price + SLCorner * _Point;
      

      if(myPosition.isPositionInRange(range_unit, current_price, POSITION_TYPE_SELL)) return;
      if(myTrade.isInvalidTrade(top, myTrade.Bid - range_unit)) return;
      if(ciOsma.Main(0) > 0) return;
      trade.Sell(myTrade.lot, NULL, myTrade.Bid, top, myTrade.Bid - range_unit, NULL);
   }

   else if(current_price > lowest_price + highest_lowest_range * CornerCri && current_price < highest_price - highest_lowest_range * CornerCri) {
      range_unit = CorePriceCri*_Point;
      top = highest_price - highest_lowest_range * CornerCri + SLCore*highest_lowest_range;
      bottom = lowest_price + highest_lowest_range * CornerCri - SLCore*highest_lowest_range;

      if(ciOsma.Main(0) > 0) {
         if(myPosition.isPositionInRange(range_unit, current_price, POSITION_TYPE_BUY)) return;
         if(myTrade.isInvalidTrade(bottom, myTrade.Ask + range_unit)) return;
         trade.Buy(myTrade.lot, NULL, myTrade.Ask, bottom, myTrade.Ask + range_unit, NULL);
      }

      else if(ciOsma.Main(0) < 0) {
         if(myPosition.isPositionInRange(range_unit, current_price, POSITION_TYPE_SELL)) return;
         if(myTrade.isInvalidTrade(top, myTrade.Bid - range_unit)) return;
         trade.Sell(myTrade.lot, NULL, myTrade.Bid, top, myTrade.Bid - range_unit, NULL);
      }
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
double OnTester() {
   MyTest myTest;
   double result =  myTest.min_dd_and_mathsqrt_profit_trades();
   return  result;
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
