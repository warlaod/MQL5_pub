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
#include <Original\Optimization.mqh>
#include <Indicators\TimeSeries.mqh>
#include <Indicators\Oscilators.mqh>
#include <Indicators\Trend.mqh>
#include <Indicators\BillWilliams.mqh>
#include <Indicators\Volumes.mqh>
#include <Trade\PositionInfo.mqh>

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
CiIchimoku Ichimoku;
int OnInit() {
   MyUtils myutils(60 * 50);
   myutils.Init();
   Ichimoku.Create(_Symbol, Timeframe, 9, 26, 52);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   Refresh();
   Check();
   
   Ichimoku.Refresh();
   myPrice.Refresh();
   myPosition.Trailings(POSITION_TYPE_BUY,Ichimoku.TenkanSen(0),10*pips);
   myPosition.Trailings(POSITION_TYPE_SELL,Ichimoku.TenkanSen(0),10*pips);

   //myPosition.CloseAllPositionsInMinute();
   if(!myTrade.isCurrentTradable || !myTrade.isTradable) return;

   

   if(isIchimokuPerferctOrder(1, ORDER_TYPE_BUY)) {
      if(isIchimokuPerferctOrder(2, ORDER_TYPE_BUY)) return;

      myTrade.setSignal(ORDER_TYPE_BUY);
   }
   if(isIchimokuPerferctOrder(1, ORDER_TYPE_SELL)) {
      if(isIchimokuPerferctOrder(2, ORDER_TYPE_SELL)) return;

      myTrade.setSignal(ORDER_TYPE_BUY);
   }


   double PriceUnit = pips;
   if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions) {
      if(myTrade.Buy(myTrade.Ask - PriceUnit * SLCoef, myTrade.Ask + PriceUnit * TPCoef)) {
         for(int i = 0; i < myPosition.BuyTickets.Total(); i++) {
            myPosition.AddListForTrailings(myPosition.BuyTickets.At(i));
         }
      }
   }
   if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions) {
      if(myTrade.Sell(myTrade.Bid + PriceUnit * SLCoef, myTrade.Bid - PriceUnit * TPCoef)) {
         for(int i = 0; i < myPosition.SellTickets.Total(); i++) {
            myPosition.AddListForTrailings(myPosition.SellTickets.At(i));
         }
      }
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isIchimokuPerferctOrder(int i, ENUM_ORDER_TYPE OrderType) {
   if(ORDER_TYPE_BUY) {
      return (isBetween(myPrice.At(i).low, Ichimoku.TenkanSen(i), Ichimoku.KijunSen(i)) && isBetween(Ichimoku.KijunSen(i), Ichimoku.SenkouSpanA(i), Ichimoku.SenkouSpanB(i)));
   } else
      return (isBetween(Ichimoku.SenkouSpanB(i), Ichimoku.SenkouSpanA(i), Ichimoku.KijunSen(i)) && isBetween(Ichimoku.KijunSen(i), Ichimoku.TenkanSen(i), myPrice.At(i).high));
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
