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
input int StdDevPeriod,k;
input double StdDevCri;
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
CiSAR SAR;
CiStdDev StdDev;
CiStochastic Stochastic;
int OnInit() {
  MyUtils myutils(60 * 27);
  myutils.Init();
  SAR.Create(_Symbol,Timeframe,0.02,0.2);
  StdDev.Create(_Symbol,Timeframe,StdDevPeriod,0,MODE_EMA,PRICE_CLOSE);
  Stochastic.Create(_Symbol,Timeframe,k,3,3,MODE_EMA,STO_LOWHIGH);
  return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
  Refresh();
  Check();

  SAR.Refresh();
  StdDev.Refresh();
  Stochastic.Refresh();
  myPrice.Refresh();

  if(Stochastic.Main(0) > 70) {
    if(isDeadCross(Stochastic.Main(1),Stochastic.Signal(1),Stochastic.Main(0),Stochastic.Signal(0))) myPosition.CloseAllPositions(POSITION_TYPE_BUY);
  }
  if(Stochastic.Main(0) < 30) {
    if(isGoldenCross(Stochastic.Main(1),Stochastic.Signal(1),Stochastic.Main(0),Stochastic.Signal(0))) myPosition.CloseAllPositions(POSITION_TYPE_SELL);
  }

  //myPosition.CloseAllPositionsInMinute(positionCloseMin);

  if(!myTrade.istradable || !tradable) return;

  if(StdDev.Main(0) < StdDevCri) return;

  if(isDeadCross(myPrice.At(1).close,SAR.Main(1),myPrice.At(0).close,SAR.Main(0))) myTrade.setSignal(ORDER_TYPE_SELL);
  if(isGoldenCross(myPrice.At(1).close,SAR.Main(1),myPrice.At(0).close,SAR.Main(0)))
    myTrade.setSignal(ORDER_TYPE_BUY);

  double PriceUnit = 10 * _Point;
  if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions / 2 ) myTrade.Buy(SAR.Main(0), PriceUnit * TPCoef);
  if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions / 2 ) myTrade.Sell(SAR.Main(0), PriceUnit * TPCoef);


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
