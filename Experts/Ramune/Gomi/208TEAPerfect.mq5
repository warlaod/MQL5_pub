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

input double SLWeight,TPWeight;
input ENUM_TIMEFRAMES Timeframe;
input double dev;
input int MAPeriod,MiddlePeriod,LongPeriod;
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
CiMA MALong,MAMiddle,MAShort;
CiBands Bands;
int OnInit() {
  MyUtils myutils(60 * 27);
  myutils.Init();
  MAShort.Create(_Symbol,Timeframe,MAPeriod,0,MODE_EMA,PRICE_CLOSE);
  MAMiddle.Create(_Symbol,Timeframe,MAPeriod*MiddlePeriod,0,MODE_EMA,PRICE_CLOSE);
  MALong.Create(_Symbol,Timeframe,MAPeriod*MiddlePeriod*LongPeriod,9,MODE_EMA,PRICE_CLOSE);
  Bands.Create(_Symbol,Timeframe,20,0,dev,PRICE_MEDIAN);
  return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
  Refresh();
  Check();

  MAShort.Refresh();
  MAMiddle.Refresh();
  MALong.Refresh();
  Bands.Refresh();

  myPosition.CloseAllPositionsInMinute(CloseMin);


  if(!myTrade.istradable || !tradable) return;

  if(isBetween(MAShort.Main(0),MAMiddle.Main(0),MALong.Main(0))) myTrade.setSignal(ORDER_TYPE_BUY);
  if(isBetween(MALong.Main(0),MAMiddle.Main(0),MAShort.Main(0))) myTrade.setSignal(ORDER_TYPE_SELL);




  double PriceUnit = 10 * _Point;
  if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions / 2 ) {
	if(myPosition.isPositionInRange(MathAbs(myTrade.Ask - Bands.Lower(0)),POSITION_TYPE_BUY)) return;
    myTrade.Buy(Bands.Lower(0), Bands.Upper(0));
  }
  if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions / 2 ) {
	if(myPosition.isPositionInRange(MathAbs(myTrade.Bid - Bands.Upper(0)),POSITION_TYPE_SELL)) return;
    myTrade.Sell(Bands.Upper(0), Bands.Lower(0));
  }


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
