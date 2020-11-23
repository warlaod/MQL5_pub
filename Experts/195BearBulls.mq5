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
#include <Indicators\TimeSeries.mqh>
#include <Indicators\Oscilators.mqh>
#include <Indicators\Trend.mqh>
#include <Indicators\BillWilliams.mqh>

input double SLCoef,TPCoef;
input ENUM_TIMEFRAMES Timeframe;
input int MAPeriod,StopLossPeriod;
bool tradable = false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyTrade myTrade();
MyDate myDate();
MyPrice myPrice(Timeframe, 3);
MyOrder myOrder(Timeframe);
CurrencyStrength CS(Timeframe, 1);
CiMA MA;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
  MyUtils myutils(60 * 27);
  myutils.Init();
  MA.Create(_Symbol,Timeframe,MAPeriod,0,MODE_SMA,PRICE_CLOSE);
  return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
  Refresh();
  Check();
  MA.Refresh();
  myPrice.Refresh();

  //myPosition.CloseAllPositionsInMinute(positionCloseMin);

  if(!myTrade.istradable || !tradable) return;

  if(isBetween(myPrice.At(1).high,MA.Main(1),myPrice.At(1).low)) {
    if(myPrice.At(2).high < MA.Main(2) ) myTrade.setSignal(ORDER_TYPE_BUY);
    if(myPrice.At(2).low > MA.Main(2) ) myTrade.setSignal(ORDER_TYPE_SELL);

  }

  double PriceUnit = 10 * _Point;
  if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions / 2 ) {
    double SL = myPrice.Lowest(0,StopLossPeriod);
    double TP = myTrade.Ask + PriceUnit*TPCoef;
    myTrade.Buy(SL,TP);
  }
  if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions / 2 ) {
    double SL = myPrice.Higest(0,StopLossPeriod);
    double TP = myTrade.Bid - PriceUnit*TPCoef;
    myTrade.Sell(SL,TP);
  }

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer() {
  myPosition.Refresh();
  myTrade.Refresh();

  tradable = true;

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
  myOrder.Refresh();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Check() {
  myTrade.CheckSpread();
  //myDate.isInTime("01:00", "07:00");
  if(myOrder.wasOrderedInTheSameBar()) myTrade.istradable = false;
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
