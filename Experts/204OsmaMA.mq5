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
input int MAPeriod;
input int TrendPeriod;
input int TrendCri;
input ENUM_TIMEFRAMES Timeframe,ATRTimeframe;
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
CiOsMA Osma;
CiMA MA;
CiATR ATR;
int OnInit() {
  MyUtils myutils(60 * 27);
  myutils.Init();
  Osma.Create(_Symbol,Timeframe,12,26,9,PRICE_CLOSE);
  MA.Create(_Symbol,Timeframe,MAPeriod,0,MODE_EMA,PRICE_CLOSE);
  ATR.Create(_Symbol,ATRTimeframe,14);
  return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
  Refresh();
  Check();
  Osma.Refresh();
  MA.Refresh();
  ATR.Refresh();


  //myPosition.CloseAllPositionsInMinute(positionCloseMin);

  if(!myTrade.istradable || !tradable) return;

  double Trend = MA.Main(0) - MA.Main(TrendPeriod);

  if(Trend > TrendCri*_Point) {
    if(isTurnedToRise(Osma.Main(2),Osma.Main(1))) myTrade.setSignal(ORDER_TYPE_BUY);
  }

  if(Trend < -TrendCri*_Point) {
    if(isTurnedToDown(Osma.Main(2),Osma.Main(1))) myTrade.setSignal(ORDER_TYPE_SELL);
  }



  double PriceUnit = 10 * _Point;
  if(!myPosition.isPositionInRange(PriceUnit*TPCoef,myTrade.Ask,POSITION_TYPE_BUY))
    myTrade.Buy(MA.Main(0), myTrade.Ask + PriceUnit * TPCoef);

  if(!myPosition.isPositionInRange(PriceUnit*TPCoef,myTrade.Bid,POSITION_TYPE_SELL))
    myTrade.Sell(MA.Main(0), myTrade.Bid - PriceUnit * TPCoef);


}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer() {
  myPosition.Refresh();
  myTrade.Refresh();
  myDate.Refresh();

  tradable = true;

  //if(myDate.isFridayEnd() || myDate.isYearEnd()) myTrade.istradable = false;
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
