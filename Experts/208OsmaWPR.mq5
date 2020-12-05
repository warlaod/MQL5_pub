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

input double SLWeight,TPWeight,OsmaWeight;
input ENUM_TIMEFRAMES Timeframe;
input int WPRPeriod,WPRCri;
input double TPPeriod,SLPeriod;
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

CiWPR WPR;
CiOsMA Osma;
int OnInit() {
  MyUtils myutils(60 * 27);
  myutils.Init();
  WPR.Create(_Symbol,Timeframe,WPRPeriod);
  Osma.Create(_Symbol,Timeframe,12,26,9,PRICE_MEDIAN);
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
  Osma.Refresh();
  WPR.Refresh();
  myPrice.Refresh();

  myPosition.CloseAllPositionsInMinute(CloseMin);

  if(!myTrade.istradable || !tradable) return;

  double OsmaCri = 10*_Point*MathPow(2, OsmaWeight);
  if(Osma.Main(0) > OsmaCri && Osma.Main(0) > Osma.Main(1) && WPR.Main(0) < -100+WPRCri) myTrade.setSignal(ORDER_TYPE_BUY);
  if(Osma.Main(0) < -OsmaCri && Osma.Main(0) < Osma.Main(1) && WPR.Main(0) > -WPRCri) myTrade.setSignal(ORDER_TYPE_SELL);



  double PriceUnit = 10 * _Point;

  double SLPeri = MathPow(2,SLPeriod);
  double TPPeri = MathPow(2,TPPeriod);
  if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions / 2 ) {
    double Highest = myPrice.Highest(0,TPPeri);
    double Lowest = myPrice.Lowest(0,SLPeri);
    //if(myPosition.isPositionInRange(MathAbs(Highest-myTrade.Ask),POSITION_TYPE_BUY)) return;
    myTrade.Buy(Lowest, Highest);
  }
  if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions / 2 ) {
    double Highest = myPrice.Highest(0,SLPeri);
    double Lowest = myPrice.Lowest(0,TPPeri);
    //if(myPosition.isPositionInRange(MathAbs(Lowest-myTrade.Bid),POSITION_TYPE_SELL)) return;
    myTrade.Sell(Highest,Lowest);
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
  if(myOrder.wasOrderedInTheSameBar())
    myTrade.istradable = false;
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
