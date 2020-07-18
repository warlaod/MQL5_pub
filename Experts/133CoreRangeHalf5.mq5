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
#include <Trade\OrderInfo.mqh>
CiOsMA ciOsma;
CiATR ciATR;
CiHigh ciHigh;
CiLow ciLow;
CiClose ciClose;
COrderInfo cOrderInfo;
CTrade trade;


MqlDateTime dt;
string range;


input ENUM_TIMEFRAMES OsmaTimeframe;
input ENUM_APPLIED_PRICE OsmaAppliedPrice;

input double CornerCri;
input int CornerPriceUnitCoef, CoreRangePriceUnitCoef;

input int PriceCount;
input int SL;
input int Timer;

int spreadcoutn = 0;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPrice myPrice(PriceTimeframe, PriceCount);
MyPosition myPosition;
MyTrade myTrade(0.01, false);
int OnInit() {
   MyUtils myutils(1, 60 * Timer);
   myutils.Init();
   ciOsma.Create(_Symbol, OsmaTimeframe, 12, 25, 9, OsmaAppliedPrice);

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer() {

   ciOsma.Refresh();

   myPrice.Refresh();
   myPosition.Refresh();
   myTrade.Refresh();
   ciOsma.Refresh();

   double lowest_price = myPrice.Lowest();
   double highest_price = myPrice.Higest();
   double highest_lowest_range = highest_price - lowest_price;
   double current_price = myPrice.getData(0, PriceTimeframe).close;

   double bottom, top;
   double range_unit;
   bottom = lowest_price - SL * _Point;
   top = highest_price + SL * _Point;

   if(current_price < lowest_price + highest_lowest_range * CornerCri) {

      range_unit = highest_lowest_range / CornerPriceUnitCoef;

      if(myPosition.isPositionInRange(range_unit, current_price, POSITION_TYPE_BUY)) return;
      if(myTrade.isInvalidTrade(bottom, myTrade.Ask + range_unit)) return;
      if(ciOsma.Main(0) < 0) return;
      trade.Buy(myTrade.lot, NULL, myTrade.Ask, bottom, myTrade.Ask + range_unit, NULL);
   }


   else if(current_price > highest_price - highest_lowest_range * CornerCri) {

      range_unit = highest_lowest_range / CornerPriceUnitCoef;

      if(myPosition.isPositionInRange(range_unit, current_price, POSITION_TYPE_SELL)) return;
      if(myTrade.isInvalidTrade(top, myTrade.Bid - range_unit)) return;
      if(ciOsma.Main(0) > 0) return;
      trade.Sell(myTrade.lot, NULL, myTrade.Bid, top, myTrade.Bid - range_unit, NULL);
   }

   else if(current_price > lowest_price + highest_lowest_range * CornerCri && current_price < highest_price - highest_lowest_range * CornerCri) {
      range_unit = highest_lowest_range / CoreRangePriceUnitCoef;

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
