
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
// 252StopLossRangerADX
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
#include <Original\MyHistory.mqh>
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

input mis_MarcosTMP timeFrame = _H8;
input mis_MarcosTMP trailTimeframe = _M30;
input mis_MarcosTMP SLTimeframe = _M30;
ENUM_TIMEFRAMES Timeframe = defMarcoTiempo(timeFrame);
ENUM_TIMEFRAMES TrailTimeframe = defMarcoTiempo(trailTimeframe);
bool tradable = false;
double PriceToPips = PriceToPips();
double pips = PointToPips();

input int PriceCount = 4;
input double CoreCri,HalfStopCri;
input int ADXMainCri = 6;
input int ADXSubCri = 12;
input int TrailPeriod,SLPeriod;
input double SellLotDiv;
input double PriceUnitCri;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

MyPosition myPosition;
MyTrade myTrade();
MyDate myDate(Timeframe);
MyPrice myPrice(PERIOD_MN1);
MyPrice myTrailPrice(TrailTimeframe);
MyHistory myHistory(Timeframe);
MyOrder myOrder(myDate.BarTime);
CurrencyStrength CS(Timeframe, 1);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CiADX ADX;
int OnInit() {
   MyUtils myutils(60 * 1);
   myutils.Init();
   ADX.Create(_Symbol, Timeframe, 14);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double PriceUnit = MathPow(2,PriceUnitCri)*pips;
void OnTimer() {
   IsCurrentTradable = true;
   Signal = NULL;

   myPosition.Refresh();
   double TrailLowest = myTrailPrice.Lowest(0, TrailPeriod);
   double TrailHighest = myTrailPrice.Highest(0, TrailPeriod);
   myPosition.CheckTargetPriceProfitableForTrailings(POSITION_TYPE_BUY, TrailLowest);
   myPosition.CheckTargetPriceProfitableForTrailings(POSITION_TYPE_SELL, TrailHighest);
   myPosition.Trailings(POSITION_TYPE_BUY, TrailLowest,100000);
   myPosition.Trailings(POSITION_TYPE_SELL, TrailHighest,0);

   ADX.Refresh();
   if(ADX.Main(0) < ADXMainCri) return;
   if(!isBetween(ADX.Main(0), ADX.Main(1), ADX.Main(2))) return;

   myPrice.Refresh(1);
   myPosition.Refresh();
   Check();

   double Lowest = myPrice.Lowest(0, PriceCount);
   double Highest = myPrice.Highest(0, PriceCount);
   double Current = myPrice.At(0).close;
   double perB = (Current - Lowest) / (Highest - Lowest);

   if(perB > 1 - HalfStopCri || perB < HalfStopCri) return;

   double bottom, top;

   myTrade.Refresh();
   if(perB < 0.5 - CoreCri) {
      if(isAbleToBuy()) {
         myTrade.ForceBuy(0, 1000);
      }
   }

   else if(perB > 0.5 + CoreCri) {
      if(isAbleToSell()) {
         myTrade.ForceSell(1000, 0);
      }
   }

   else if(isBetween(0.5 + CoreCri, perB, 0.5 - CoreCri)) {
      if(isAbleToBuy())
         myTrade.ForceBuy(Lot(ORDER_TYPE_BUY), 0, 1000);
      else if(isAbleToSell())
         myTrade.ForceSell(Lot(ORDER_TYPE_SELL), 1000, 0);
   }
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isAbleToBuy() {
   if(ADX.Plus(0) > ADXSubCri && ADX.Plus(0) > ADX.Minus(0)) {
      if(isBetween(ADX.Plus(0), ADX.Plus(1), ADX.Plus(2))) {
         if(!myPosition.isPositionInRange(POSITION_TYPE_BUY, PriceUnit))
            return true;
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isAbleToSell() {
   if(ADX.Minus(0) > ADXSubCri && ADX.Minus(0) > ADX.Plus(0)) {
      if(isBetween(ADX.Minus(0), ADX.Minus(1), ADX.Minus(2))) {
         if(!myPosition.isPositionInRange(POSITION_TYPE_SELL, PriceUnit))
            return true;
      }
   }
   return false;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double OnTester() {
   MyTest myTest;
   double result =  myTest.min_dd_and_mathsqrt_trades();
   return  result;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Check() {
   if(myTrade.isLowerBalance() || myTrade.isLowerMarginLevel()) {
      myPosition.CloseAllPositions(POSITION_TYPE_BUY);
      myPosition.CloseAllPositions(POSITION_TYPE_SELL);
      Print("EA stopped because of lower balance or lower margin level  ");
      ExpertRemove();
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Lot(ENUM_ORDER_TYPE orderType) {
   CArrayLong Tickets = (orderType == ORDER_TYPE_BUY) ? myPosition.BuyTickets : myPosition.SellTickets;
   double lot = 0;
   for(int i = 0; i < Tickets.Total(); i++) {
      myPosition.SelectByTicket(myPosition.BuyTickets.At(i));
      lot += myPosition.Volume();
   }
   for(int i = 0; i < Tickets.Total(); i++) {
      myPosition.SelectByTicket(myPosition.SellTickets.At(i));
      lot -= myPosition.Volume();
   }
   lot = NormalizeDouble(lot / SellLotDiv, myTrade.LotDigits);
   if(lot < myTrade.minlot) lot = myTrade.minlot;
   else if(lot > myTrade.maxlot) lot = myTrade.maxlot;
   return lot;
}
//+------------------------------------------------------------------+
