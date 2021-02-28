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
input mis_MarcosTMP timeFrame;
ENUM_TIMEFRAMES Timeframe = defMarcoTiempo(timeFrame);
bool tradable = false;
double PriceToPips = PriceToPips();
double pips = ToPips();
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyTrade myTrade();
MyDate myDate();
MyPrice myPrice(Timeframe, 3);
MyOrder myOrder(Timeframe);
CurrencyStrength CS(Timeframe, 1);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyFractal myFractal(4);
int OnInit() {
   MyUtils myutils(60 * 50);
   myutils.Init();
   myFractal.Create(_Symbol, Timeframe);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   Refresh();
   Check();

   myFractal.myRefresh();
   myFractal.SearchMUpperIndex();

//   for(int i = 0; i < myPosition.BuyTickets.Total(); i++) {
//      ulong ticket = myPosition.BuyTickets.At(i);
//      myPosition.SelectByTicket(ticket);
//      if(myPosition.TargetPriceProfit(myFractal.SLower.At(0)) > 0)
//         myPosition.AddListForTrailings(ticket);
//   }
//   
//   for(int i = 0; i < myPosition.SellTickets.Total(); i++) {
//      ulong ticket = myPosition.SellTickets.At(i);
//      myPosition.SelectByTicket(ticket);
//      if(myPosition.TargetPriceProfit(myFractal.SUpper.At(0)) > 0)
//         myPosition.AddListForTrailings(ticket);
//   }

   myPrice.Refresh();

   //myPosition.Trailings(POSITION_TYPE_BUY, myFractal.SLower.At(0), myTrade.Ask + 30*pips);
   //myPosition.Trailings(POSITION_TYPE_SELL, myFractal.SUpper.At(0), myTrade.Bid - 30*pips);

   //myPosition.CloseAllPositionsInMinute();
   if(!myTrade.isCurrentTradable || !myTrade.isTradable) return;

   if(!myFractal.isMSLinedCorrectly()) return;


   double PriceUnit = pips;
   //if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions) {
   //   myTrade.Buy(myFractal.MLower.At(0), myTrade.Ask + PriceUnit * TPCoef);
   //}
   //if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions) {
   //   myTrade.Sell(myFractal.MUpper.At(0), myTrade.Bid - PriceUnit * TPCoef);
   //}


}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer() {
   myPosition.Refresh();
   myTrade.Refresh();
   myDate.Refresh();

   if(myDate.isFridayEnd() || myDate.isYearEnd() || myTrade.isLowerBalance() || myTrade.isLowerMarginLevel()) {
      myPosition.CloseAllPositions(POSITION_TYPE_BUY);
      myPosition.CloseAllPositions(POSITION_TYPE_SELL);
      myTrade.isTradable = false;
   } else {
      myTrade.isTradable = true;
   }
}

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
void Check() {
   //myTrade.CheckSpread();
   myDate.Refresh();
   myOrder.Refresh();
   if(myDate.isMondayStart()) myTrade.isCurrentTradable = false;
   if(myOrder.wasOrderedInTheSameBar()) myTrade.isCurrentTradable = false;
}
//+------------------------------------------------------------------+
