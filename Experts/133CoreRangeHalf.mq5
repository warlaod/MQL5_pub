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
#include <Indicators\TimeSeries.mqh>
#include <Indicators\Oscilators.mqh>
#include <Trade\OrderInfo.mqh>
CiOsMA ciOsma;
CiATR ciATR;
CiHigh ciHigh;
CiLow ciLow;
CiClose ciClose;
COrderInfo cOrderInfo;
MyTrade myTrade;
CTrade trade;

MqlDateTime dt;
input int denom = 30000;
double lot = 0.10;
double  Bid, Ask;
string range;


input ENUM_TIMEFRAMES OsmaTimeframe, ATRTimeframe;
input ENUM_APPLIED_PRICE OsmaAppliedPrice;

input double CornerPriceUnitCoef, CoreRangePriceUnitCoef, CornerCri;

input int PriceCount;
input int SL;


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   MyUtils myutils(1, 3600 * 1);
   myutils.Init();
   ciOsma.Create(_Symbol, OsmaTimeframe, 12, 25, 9, OsmaAppliedPrice);
   ciATR.Create(_Symbol, ATRTimeframe, 14);

   ciHigh.Create(_Symbol, PERIOD_MN1);
   ciLow.Create(_Symbol, PERIOD_MN1);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer() {
   ciOsma.Refresh();
   ciATR.Refresh();
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

   myTrade.CheckSpread();
   if(!myTrade.istradable) {
      return;
   }

   range = "";
   
   
   double bottom, top;
   double range_unit;

   if(current_price < lowest_price + lowest_price * CornerCri) {
      bottom = lowest_price - SL * _Point;
      range_unit = ciATR.Main(0) * CornerPriceUnitCoef;
      if(myTrade.isPositionInRange(range_unit, current_price, POSITION_TYPE_BUY))
         trade.Buy(lot, NULL, Ask, bottom, Ask + range_unit, NULL);

   }

   else if(current_price > highest_price - highest_lowest_range * CornerCri) {
      top = highest_price + SL * _Point;
      range_unit = ciATR.Main(0) * CornerPriceUnitCoef;
      if(myTrade.isPositionInRange(range_unit, current_price, POSITION_TYPE_SELL))
         trade.Sell(lot, NULL, Bid, top, Bid - range_unit, NULL);
   }

   else if(current_price > lowest_price + highest_lowest_range * CornerCri && current_price < highest_price - highest_lowest_range * CornerCri) {
      bottom = highest_price - highest_lowest_range * CornerCri;
      top = lowest_price + highest_lowest_range * CornerCri;
      range_unit = ciATR.Main(0) * CoreRangePriceUnitCoef;

      if(ciOsma.Main(0) > 0) {
         if(myTrade.isPositionInRange(range_unit, current_price, POSITION_TYPE_BUY))
            trade.Buy(lot, NULL, Ask, bottom, Ask + range_unit, NULL);
      }

      else if(ciOsma.Main(0) < 0) {
         if(myTrade.isPositionInRange(range_unit, current_price, POSITION_TYPE_SELL))
            trade.Sell(lot, NULL, Bid, top, Bid - range_unit, NULL);
      }
   }
}

void SetTrade(){

}

/*
range = "";
double TotalPositions = 0;
double bottom = 0;
double top = 0;
double range_unit = 0;



} else if(current_price > highest_price - highest_lowest_range * CornerCri) {
   range = "Upeer";
   TotalPositions = MathRound((highest_lowest_range * CornerCri) / (ciATR.Main(0) * CornerPriceUnitCoef));
} else if(current_price > lowest_price + highest_lowest_range * CornerCri && current_price < highest_price - highest_lowest_range * CornerCri) {
   range = "Middle";
   TotalPositions = MathRound(((1 - 2 * CornerCri) * highest_lowest_range) / (ciATR.Main(0) * CoreRangePriceUnitCoef));
}

if(range == "Lower") {
   bottom = lowest_price - SL * _Point;
   top = lowest_price + highest_lowest_range * CornerCri;
   range_unit = ciATR.Main(0) * CornerPriceUnitCoef;
   TotalPositions = MathRound((top - bottom) / range_unit);

   string where = WherePositonIsInRange(range_unit, POSITION_TYPE_BUY);
   switch(where) {
   case 'Both':
      Print("CASE A");
      break;
   case 'Upper':
   case 'Lower':
      Print("CASE B or C");
      break;
   default:
      Print("NOT A, B or C");
      break;
   }

   for(int i = 1; i < TotalPositions; i++) {
      trade.Buy(lot, NULL, bottom + range_unit * i, bottom, bottom + range_unit * (i + 1), NULL);
   }
}

if(range == "Upper") {
   bottom = highest_price - highest_lowest_range * CornerCri;
   top = highest_price + SL * _Point;
   range_unit = ciATR.Main(0) * CornerPriceUnitCoef;
   TotalPositions = MathRound((top - bottom) / range_unit);

   for(int i = 1; i < TotalPositions; i++) {
      trade.Sell(lot, NULL, top - range_unit * i, top, top - range_unit * (i + 1), NULL);
   }
}

if(range == "Middle") {
   bottom = highest_price - highest_lowest_range * CornerCri;
   top = lowest_price + highest_lowest_range * CornerCri;
   range_unit = ciATR.Main(0) * CoreRangePriceUnitCoef;
   TotalPositions = MathRound((top - bottom) / range_unit);

   if(Osma[0] > 0) {
      for(int i = 1; i < TotalPositions; i++) {
         trade.Buy(lot, NULL, bottom + range_unit * i, bottom, bottom + range_unit * (i + 1), NULL);
      }
   }
} else if(Osma[0] < 0) {
   for(int i = 1; i < TotalPositions; i++) {
      trade.Sell(lot, NULL, top - range_unit * i, top, top - range_unit * (i + 1), NULL);
   }
}
}

*/
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
double OnTester() {
   if(!setVariables()) {
      return -99999999;
   }
   return testingNormal();
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
