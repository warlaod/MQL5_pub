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
#include <Original\Optimization.mqh>
#include <Indicators\TimeSeries.mqh>
#include <Indicators\Oscilators.mqh>
#include <Indicators\Trend.mqh>
#include <Indicators\BillWilliams.mqh>
#include <Indicators\Volumes.mqh>
#include <Trade\PositionInfo.mqh>
#include <Arrays\ArrayLong.mqh>

input double SLCoef, TPCoef;
input mis_MarcosTMP timeFrame;
ENUM_TIMEFRAMES Timeframe = defMarcoTiempo(timeFrame);
bool tradable = false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
CPositionInfo cPositionInfo;
MyTrade myTrade();
MyDate myDate();
MyPrice myPrice(Timeframe, 7);
MyOrder myOrder(Timeframe);
CurrencyStrength CS(Timeframe, 1);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CiBands Band1, Band2;
int OnInit() {
   MyUtils myutils(60 * 1);
   myutils.Init();

   Band1.Create(_Symbol, Timeframe, 20, 0, 1, PRICE_CLOSE);
   Band2.Create(_Symbol, Timeframe, 20, 0, 2, PRICE_CLOSE);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   Refresh();
   Check();

   myPosition.Trailings(POSITION_TYPE_BUY, myPrice.Lowest(0, 2), myTrade.Ask + 50 * _Point);
   myPosition.Trailings(POSITION_TYPE_SELL, myPrice.Highest(0, 2), myTrade.Bid - 50 * _Point);

   //myPosition.CloseAllPositionsInMinute();
   if(!myTrade.istradable || !tradable) return;

   Band1.Refresh();
   Band2.Refresh();
   myPrice.Refresh();

   if(myPrice.At(1).close > Band1.Lower(1) && myPrice.At(0).close < Band1.Base(0)) {
      for(int i = 2; i <= 5; i++) {
         if(myPrice.At(i).close > Band1.Lower(i)) return;
      }
      myTrade.setSignal(ORDER_TYPE_BUY);
   }

   if(Band2.Base(0) < myPrice.At(0).high) {
      CArrayLong Tickets = myPosition.BuyTickets;
      for(int i = 0; i < Tickets.Total(); i++) {
         ulong ticket = Tickets.At(i);
         cPositionInfo.SelectByTicket(ticket);
         if(cPositionInfo.StopLoss() < 2 * cPositionInfo.Profit())
            myPosition.AddListForTrailings(ticket);
      }
   }


   if(myPrice.At(1).close < Band1.Upper(1) && myPrice.At(0).close > Band1.Base(0)) {
      for(int i = 2; i <= 5; i++) {
         if(myPrice.At(i).close < Band1.Upper(i)) return;
      }
      myTrade.setSignal(ORDER_TYPE_SELL);
   }

   if(myPrice.At(1).close > Band1.Lower(1) && myPrice.At(0).close < Band1.Base(0)) {
      for(int i = 2; i <= 5; i++) {
         if(myPrice.At(i).close > Band1.Lower(i)) return;
      }
      myTrade.setSignal(ORDER_TYPE_BUY);
   }


   double PriceUnit = Band2.Upper(0) - Band2.Base(0);
   if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions / 2 ) {
      myTrade.Buy(myTrade.Ask - PriceUnit * SLCoef, myTrade.Ask + PriceUnit * TPCoef);
   }



}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer() {
   myPosition.Refresh();
   myTrade.Refresh();
   myDate.Refresh();
   myOrder.Refresh();

   tradable = true;

   //if(!myDate.isInTime("01:00", "07:00")) myTrade.istradable = false;
   if(myOrder.wasOrderedInTheSameBar()) myTrade.istradable = false;
   if(myDate.isFridayEnd() || myDate.isYearEnd()) myTrade.istradable = false;
   myTrade.CheckBalance();
   myTrade.CheckMarginLevel();

   if(!myTrade.istradable) {
      myPosition.CloseAllPositions(POSITION_TYPE_BUY);
      myPosition.CloseAllPositions(POSITION_TYPE_SELL);
      tradable = false;
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

}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
