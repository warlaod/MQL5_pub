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

input double SLCoef, TPCoef;
input int ADXCri;
input double SellLotDiv;
input int PricePeriod, PDev, ADXPeriod, TrailPeriod,SLPeriod;
input mis_MarcosTMP timeFrame, trailTimeframe,slTimeframe;
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
MyPrice myPrice(PERIOD_MN1), myTrailPrice(TrailTimeframe),mySLPrice(SLTimeframe);
MyHistory myHistory(Timeframe);
MyOrder myOrder(myDate.BarTime);
CurrencyStrength CS(Timeframe, 1);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CiADX ADX;
MyChart Chart;
int OnInit() {
   MyUtils myutils(60 * 50);
   myutils.Init();
   ADX.Create(_Symbol, Timeframe, 14);
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   IsCurrentTradable = true;
   Signal = -1;

   //myOrder.Refresh();
   //myPosition.CloseAllPositionsInMinute();
   double Highest = myPrice.Highest(0, PricePeriod);
   double Lowest = myPrice.Lowest(0, PricePeriod);
   double PriceUnit = (Highest - Lowest) / PDev;

   myPosition.Refresh();
   double TrailLowest = myTrailPrice.Lowest(1, TrailPeriod);
   double TrailHighest = myTrailPrice.Highest(1, TrailPeriod);
   myPosition.CheckTargetPriceProfitableForTrailings(POSITION_TYPE_BUY, TrailLowest);
   myPosition.CheckTargetPriceProfitableForTrailings(POSITION_TYPE_SELL, TrailHighest);
   myPosition.Trailings(POSITION_TYPE_BUY, TrailLowest);
   myPosition.Trailings(POSITION_TYPE_SELL, TrailHighest);

   Check();
   if(!IsCurrentTradable || !IsTradable) return;

   myTrade.Refresh();
   if(!myPosition.isPositionInRange(POSITION_TYPE_BUY, PriceUnit)) {
      myTrade.ForceBuy(0, 100000);
   }
   ADX.Refresh();
   if(!myPosition.isPositionInRange(POSITION_TYPE_SELL, PriceUnit)) {
      if(ADX.Minus(0) > 20) {
         if(ADX.Main(0) < ADXCri || !isRising(ADX, 1)) return;
         myTrade.ForceSell(mySLPrice.Highest(1,SLPeriod), 0, SellLot());
      }
   }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer() {
   IsTradable = true;
   if(myTrade.isLowerBalance() || myTrade.isLowerMarginLevel()) {
      myPosition.Refresh();
      myPosition.CloseAllPositions(POSITION_TYPE_BUY);
      myPosition.CloseAllPositions(POSITION_TYPE_SELL);
      Print("EA stopped because of lower balance or lower margin level  ");
      ExpertRemove();
   }
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
   //myTrade.CheckSpread();
   myDate.Refresh();
   if(myDate.isMondayStart()) IsCurrentTradable = false;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double SellLot() {
   double lot = 0;
   for(int i = 0; i < myPosition.BuyTickets.Total(); i++) {
      myPosition.SelectByTicket(myPosition.BuyTickets.At(i));
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
