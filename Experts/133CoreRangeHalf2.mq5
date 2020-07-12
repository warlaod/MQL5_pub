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
#include <Original\Ontester.mqh>
#include <Original\caluculate.mqh>
#include <Original\MyUtils.mqh>
#include <Original\MyTrade.mqh>
#include <Original\MyCalculate.mqh>
#include <Original\MyTest.mqh>
#include <Indicators\TimeSeries.mqh>
#include <Indicators\Oscilators.mqh>
#include <Trade\OrderInfo.mqh>
CiOsMA ciOsma;
CiATR ciATR;
CiHigh ciHigh;
CiLow ciLow;
CiClose ciClose;
COrderInfo cOrderInfo;
MyTrade myTrade(0.01);
CTrade trade;

MqlDateTime dt;
double  Bid, Ask;
string range;


input ENUM_TIMEFRAMES OsmaTimeframe;
input ENUM_APPLIED_PRICE OsmaAppliedPrice;

input double CornerPriceUnitCoef, CoreRangePriceUnitCoef, CornerCri;

input int PriceCount;
input int SL;
input int Timer;


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   MyUtils myutils(1, 60 * Timer);
   myutils.Init();
   ciOsma.Create(_Symbol, OsmaTimeframe, 12, 25, 9, OsmaAppliedPrice);

   ciHigh.Create(_Symbol, PERIOD_MN1);
   ciLow.Create(_Symbol, PERIOD_MN1);
   ciClose.Create(_Symbol, OsmaTimeframe);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer() {
   //myTrade.SetLot();
   myTrade.istradable = true;
   myTrade.CheckSpread();
   if(!myTrade.istradable) {
      return;
   }
   ciOsma.Refresh();
   ciHigh.Refresh();
   ciLow.Refresh();
   ciClose.Refresh();

   Ask = myTrade.Ask();
   Bid = myTrade.Bid();

   int index;
   double lowest_price = ciLow.MinValue(0, PriceCount, index);
   double highest_price = ciHigh.MaxValue(0, PriceCount, index);
   double highest_lowest_range = highest_price - lowest_price;
   double current_price = ciClose.GetData(0);



   range = "";


   double bottom, top;
   double range_unit;

   if(current_price < lowest_price + highest_lowest_range * CornerCri) {
      bottom = lowest_price - SL * _Point;
      range_unit = ciOsma.Main(0) * CornerPriceUnitCoef;

      if(myTrade.isPositionInRange(range_unit, current_price, POSITION_TYPE_BUY)) return;
      if(myTrade.isInvalidTrade(bottom, Ask + range_unit)) return;
      if(ciOsma.Main(0) < 0) return;
      trade.Buy(myTrade.lot, NULL, Ask, bottom, Ask + range_unit, NULL);
   }

   else if(current_price > highest_price - highest_lowest_range * CornerCri) {
      top = highest_price + SL * _Point;
      range_unit = ciOsma.Main(0) * CornerPriceUnitCoef;

      if(myTrade.isPositionInRange(range_unit, current_price, POSITION_TYPE_SELL)) return;
      if(myTrade.isInvalidTrade(top, Bid - range_unit)) return;
      if(ciOsma.Main(0) > 0) return;
      trade.Sell(myTrade.lot, NULL, Bid, top, Bid - range_unit, NULL);
   }

   else if(current_price > lowest_price + highest_lowest_range * CornerCri && current_price < highest_price - highest_lowest_range * CornerCri) {
      bottom = lowest_price + highest_lowest_range * CornerCri;
      top = highest_price - highest_lowest_range * CornerCri;
      range_unit = ciOsma.Main(0) * CoreRangePriceUnitCoef;

      if(ciOsma.Main(0) > 0) {
         if(myTrade.isPositionInRange(range_unit, current_price, POSITION_TYPE_BUY)) return;
         if(myTrade.isInvalidTrade(bottom, Ask + range_unit)) return;
         trade.Buy(myTrade.lot, NULL, Ask, bottom, Ask + range_unit, NULL);
      }

      else if(ciOsma.Main(0) < 0) {
         if(myTrade.isPositionInRange(range_unit, current_price, POSITION_TYPE_SELL)) return;
         if(myTrade.isInvalidTrade(top, Bid - range_unit)) return;
         trade.Sell(myTrade.lot, NULL, Bid, top, Bid - range_unit, NULL);
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
