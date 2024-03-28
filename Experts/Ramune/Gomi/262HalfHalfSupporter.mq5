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

input int ADXCri;
input double SellLotDiv;
input int TPCri;
input double PriceUnitCri;
input int PricePeriod, ADXPeriod, TrailPeriod, SLPeriod;
input mis_MarcosTMP timeFrame, trailTimeframe, slTimeframe;
ENUM_TIMEFRAMES Timeframe = defMarcoTiempo(timeFrame);
ENUM_TIMEFRAMES TrailTimeframe = defMarcoTiempo(trailTimeframe);
ENUM_TIMEFRAMES SLTimeframe = defMarcoTiempo(slTimeframe);
bool tradable = false;
double PriceToPips = PriceToPips();
double pips = PointToPips();
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyTrade myTrade();
MyDate myDate(Timeframe);
MyPrice myPrice(PERIOD_MN1), myTrailPrice(TrailTimeframe), mySLPrice(SLTimeframe);
MyHistory myHistory(Timeframe);
MyOrder myOrder(myDate.BarTime);
CurrencyStrength CS(Timeframe, 1);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CiADX ADX;
MyChart Chart;
int OnInit() {
   MyUtils myutils(60 * 1);
   myutils.Init();
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double PriceUnit = MathPow(2, PriceUnitCri)*pips;
void OnTimer() {
   IsTradable = true;
   if(myTrade.isLowerBalance() || myTrade.isLowerMarginLevel()) {
      myPosition.Refresh();
      myPosition.CloseAllPositions(POSITION_TYPE_BUY);
      myPosition.CloseAllPositions(POSITION_TYPE_SELL);
      Print("EA stopped because of lower balance or lower margin level  ");
      ExpertRemove();
   }
   IsCurrentTradable = true;

   //myOrder.Refresh();
   //myPosition.CloseAllPositionsInMinute();


   myPosition.Refresh();
   double TrailLowest = myTrailPrice.Lowest(0, TrailPeriod);
   double TrailHighest = myTrailPrice.Highest(0, TrailPeriod);
   myPosition.CheckTargetPriceProfitableForTrailings(POSITION_TYPE_BUY, TrailLowest);
   myPosition.CheckTargetPriceProfitableForTrailings(POSITION_TYPE_SELL, TrailHighest);
   myPosition.Trailings(POSITION_TYPE_BUY, TrailLowest, TPCri * pips);
   myPosition.Trailings(POSITION_TYPE_SELL, TrailHighest, TPCri * pips);

   Check();
   if(!IsCurrentTradable || !IsTradable) return;

   myPrice.Refresh(1);
   double Highest = myPrice.Highest(0, PricePeriod);
   double Lowest = myPrice.Lowest(0, PricePeriod);
   double perB = (myPrice.At(0).close - Lowest) / (Highest - Lowest);

   myTrade.Refresh();
   if(perB > 0.5) {
      if(!myPosition.isPositionInRange(POSITION_TYPE_SELL, PriceUnit)) {
         myTrade.ForceSell(0, 1000);
      }
   } else if(perB < 0.5) {
      if(!myPosition.isPositionInRange(POSITION_TYPE_BUY, PriceUnit)) {
         myTrade.ForceBuy(0, 1000);
      }
   }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double OnTester() {
   MyTest myTest;
   double result =  myTest.min_dd_and_mathsqrt_trades_without_balance();
   return  result;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Check() {
   myTrade.CheckSpread();
   myDate.Refresh();
   if(myDate.isMondayStart()) IsCurrentTradable = false;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CounterLot(ENUM_ORDER_TYPE ordeType) {
   CArrayLong Tickets = (ordeType == ORDER_TYPE_BUY) ? myPosition.BuyTickets : myPosition.SellTickets;
   double lot = 0;
   for(int i = 0; i < Tickets.Total(); i++) {
      myPosition.SelectByTicket(Tickets.At(i));
      lot += myPosition.Volume();
   }
   for(int i = 0; i < myPosition.SellTickets.Total(); i++) {
      myPosition.SelectByTicket(myPosition.SellTickets.At(i));
      lot -= myPosition.Volume();
   }
   lot = NormalizeDouble(lot / SellLotDiv, myTrade.LotDigits);
   if(lot < myTrade.minlot) lot = myTrade.minlot;
   else if(lot > myTrade.maxlot) lot = myTrade.maxlot;
   return lot;
}
//+------------------------------------------------------------------+
