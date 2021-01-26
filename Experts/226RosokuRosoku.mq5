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
#include <Original\MyCHart.mqh>
#include <Indicators\TimeSeries.mqh>
#include <Indicators\Oscilators.mqh>
#include <Indicators\Trend.mqh>
#include <Indicators\BillWilliams.mqh>
#include <Indicators\Volumes.mqh>
#include <Trade\PositionInfo.mqh>

input double SLCoef, TPCoef;
input mis_MarcosTMP timeFrame;
ENUM_TIMEFRAMES Timeframe = defMarcoTiempo(timeFrame);
input int SPriceRange, LPriceRange, RSIPeriod, perBLine, ATRPeriod;
bool tradable = false;
double topips = ToPips();
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
CiRSI RSI;
CiATR ATR;
int OnInit() {
   MyUtils myutils(60 * 1);
   myutils.Init();

   RSI.Create(_Symbol, Timeframe, RSIPeriod, PRICE_CLOSE);
   ATR.Create(_Symbol, Timeframe, ATRPeriod);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   Refresh();
   Check();



   CPositionInfo cPositionInfo;
   for(int i = 0; i < myPosition.SellTickets.Total(); i++) {
      ulong ticket = myPosition.SellTickets.At(i);
      cPositionInfo.SelectByTicket(ticket);
      if(cPositionInfo.StopLoss() < 2 * cPositionInfo.Profit()) {
         myPosition.AddListForTrailings(ticket);
         myPosition.ClosePartial(ticket, 0.5);
      }
   }
   for(int i = 0; i < myPosition.BuyTickets.Total(); i++) {
      ulong ticket = myPosition.SellTickets.At(i);
      cPositionInfo.SelectByTicket(ticket);
      if(cPositionInfo.StopLoss() < 2 * cPositionInfo.Profit()) {
         myPosition.AddListForTrailings(ticket);
         myPosition.ClosePartial(ticket, 0.5);
      }
   }

   double PriceUnit = ATR.Main(0);
   myPosition.Trailings(POSITION_TYPE_BUY,PriceUnit*2,PriceUnit*2);
    myPosition.Trailings(POSITION_TYPE_SELL,PriceUnit*2,PriceUnit*2);
   



   RSI.Refresh();
   myPrice.Refresh();
   ATR.Refresh();


//myPosition.CloseAllPositionsInMinute();
   if(!myTrade.istradable || !tradable) return;




   double LHighest = NormalizeDouble(myPrice.Highest(0, LPriceRange) + 0.0005, 3);
   double LLowest = NormalizeDouble(myPrice.Lowest(0, LPriceRange) - 0.0005, 3);
   double perB = (myPrice.At(0).close - LLowest) / (LHighest - LLowest) * 100;

   if(perB > 100 - perBLine) {
      if(RSI.Main(2) > 70 && RSI.Main(1) < 70)
         myTrade.setSignal(ORDER_TYPE_SELL);
   }

   if(perB < perBLine) {
      if(RSI.Main(2) < 30 && RSI.Main(1) > 30)
         myTrade.setSignal(ORDER_TYPE_BUY);
   }






   if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions / 2 ) {
      myTrade.Buy(myTrade.Ask - PriceUnit * SLCoef, myTrade.Ask + PriceUnit * 5 * SLCoef);
   }
   if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions / 2 ) {
      myTrade.Sell(myTrade.Bid + PriceUnit * SLCoef, myTrade.Bid - PriceUnit * 5 * SLCoef);
   }


}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer() {
   myPosition.Refresh();
   myTrade.Refresh();
   myOrder.Refresh();
   myDate.Refresh();


   tradable = true;

   //if(myOrder.wasOrderedInTheSameBar()) myTrade.istradable = false;
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
