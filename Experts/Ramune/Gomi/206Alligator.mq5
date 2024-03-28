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

input double SLWeight,TPWeight,PricePeriod;
input ENUM_TIMEFRAMES Timeframe;
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
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CloseMin = 10*MathPow(2,positionCloseMinPow);
double TPCoef = MathPow(2,TPWeight);
double SLCoef = MathPow(2,SLWeight);
CiAlligator Alligator;
int OnInit() {
  MyUtils myutils(60 * 27);
  myutils.Init();
  Alligator.Create(_Symbol,Timeframe,13.,8,8,5,5,3,MODE_EMA,PRICE_CLOSE);
  return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
  Refresh();
  Check();

  myPosition.CloseAllPositionsInMinute(CloseMin);

  Alligator.Refresh();
  myPrice.Refresh();

  if(!myTrade.istradable || !tradable) return;

  if(isBetween(Alligator.Lips(2),Alligator.Teeth(2),Alligator.Jaw(2)) && Alligator.Teeth(1) > Alligator.Lips(1)) {
    myPosition.CloseAllPositionsByProfit(POSITION_TYPE_BUY);
    myTrade.setSignal(ORDER_TYPE_SELL);
  }
  if(isBetween(Alligator.Jaw(2),Alligator.Teeth(2),Alligator.Lips(2)) && Alligator.Teeth(1) < Alligator.Lips(1)) {
    myPosition.CloseAllPositionsByProfit(POSITION_TYPE_SELL);
    myTrade.setSignal(ORDER_TYPE_BUY);
  }

  double PriceUnit = 10 * _Point;
  double Highest = myPrice.Highest(0,PricePeriod);
  double Lowest = myPrice.Lowest(0,PricePeriod);
  if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions / 2 ) myTrade.Buy(Lowest, myTrade.Ask + PriceUnit * TPWeight);
  if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions / 2 ) myTrade.Sell(Highest, myTrade.Bid - PriceUnit * TPWeight);


}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer() {
  myPosition.Refresh();
  myTrade.Refresh();
  myDate.Refresh();

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
  //myDate.Refresh();
  //if(!myDate.isInTime("08:00", "12:00")) myTrade.istradable = false;
  if(myOrder.wasOrderedInTheSameBar()) myTrade.istradable = false;
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
