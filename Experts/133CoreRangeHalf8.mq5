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
#include <Original\MyUtils.mqh>
#include <Original\MyTrade.mqh>
#include <Original\MyCalculate.mqh>
#include <Original\MyTest.mqh>
#include <Original\MyPrice.mqh>
#include <Original\MyPosition.mqh>
#include <Indicators\TimeSeries.mqh>
#include <Indicators\Oscilators.mqh>
#include <Trade\OrderInfo.mqh>
CiOsMA ciOsma;
CiATR ciATR;
COrderInfo cOrderInfo;
CTrade trade;

input ENUM_TIMEFRAMES OsmaTimeframe, ATRTimeframe;
input ENUM_APPLIED_PRICE OsmaAppliedPrice;

input double CornerCri;
input double CornerPriceUnitCoef, CoreRangePriceUnitCoef;

input int PriceCount;
input int SLCorner;
input double SLCore;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPrice myPrice(PERIOD_MN1,PriceCount);
MyPosition myPosition;
MyTrade myTrade();

// ATR, bottom,top個別
int OnInit() {
   MyUtils myutils(60 );
   myutils.Init();
   ciOsma.Create(_Symbol, OsmaTimeframe, 12, 25, 9, OsmaAppliedPrice);
   ciATR.Create(_Symbol, ATRTimeframe, 14);
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
   ciATR.Refresh();
  
   
   double lowest_price = myPrice.Lowest(0,PriceCount);
   double highest_price = myPrice.Higest(0,PriceCount);
   double highest_lowest_range = highest_price - lowest_price;
   double current_price = myPrice.getData(0).close;

   double bottom, top;
   double range_unit;

   if(current_price < lowest_price + highest_lowest_range * CornerCri) {
      range_unit = MathAbs(ciATR.Main(0)) * CornerPriceUnitCoef;
      bottom = lowest_price - SLCorner * _Point;
      
      if(myPosition.isPositionInTPRange(range_unit, current_price,POSITION_TYPE_BUY)) return;
      if(myTrade.isInvalidTrade(bottom, myTrade.Ask + range_unit)) return;
      if(ciOsma.Main(0) < 0) return;
      trade.Buy(myTrade.lot, NULL, myTrade.Ask, bottom, myTrade.Ask + range_unit, NULL);
   }


   else if(current_price > highest_price - highest_lowest_range * CornerCri) {
      range_unit = MathAbs(ciATR.Main(0)) * CornerPriceUnitCoef;
      top = highest_price + SLCorner * _Point;

      if(myPosition.isPositionInTPRange(range_unit, current_price, POSITION_TYPE_SELL)) return;
      if(myTrade.isInvalidTrade(top, myTrade.Bid - range_unit)) return;
      if(ciOsma.Main(0) > 0) return;
      trade.Sell(myTrade.lot, NULL, myTrade.Bid, top, myTrade.Bid - range_unit, NULL);
   }

   else if(current_price > lowest_price + highest_lowest_range * CornerCri && current_price < highest_price - highest_lowest_range * CornerCri) {
      range_unit = MathAbs(ciATR.Main(0)) * CoreRangePriceUnitCoef;
      top = highest_price - highest_lowest_range * CornerCri + SLCore*highest_lowest_range;
      bottom = lowest_price + highest_lowest_range * CornerCri - SLCore*highest_lowest_range;

      if(ciOsma.Main(0) > 0) {
         if(myPosition.isPositionInTPRange(range_unit, current_price, POSITION_TYPE_BUY)) return;
         if(myTrade.isInvalidTrade(bottom, myTrade.Ask + range_unit)) return;
         trade.Buy(myTrade.lot, NULL, myTrade.Ask, bottom, myTrade.Ask + range_unit, NULL);
      }

      else if(ciOsma.Main(0) < 0) {
         if(myPosition.isPositionInTPRange(range_unit, current_price, POSITION_TYPE_SELL)) return;
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
