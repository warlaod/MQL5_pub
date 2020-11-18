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
#include <Trade\Trade.mqh>
#include <Original\MyUtils.mqh>
#include <Original\MyTrade.mqh>
#include <Original\Oyokawa.mqh>
#include <Original\MyCalculate.mqh>
#include <Original\MyTest.mqh>
#include <Original\MyPrice.mqh>
#include <Original\MyDate.mqh>
#include <Original\MyPosition.mqh>
#include <Original\MyOrder.mqh>
#include <Indicators\TimeSeries.mqh>
#include <Indicators\Oscilators.mqh>
#include <Indicators\Trend.mqh>
#include <Trade\OrderInfo.mqh>
#include <Arrays\ArrayDouble.mqh>
#include <Indicators\BillWilliams.mqh>
CTrade trade;
CiATR ciATR;
CiBands ciBands;
CiMACD ciLongMACD,ciShortMACD;
#include <Generic\Interfaces\IComparable.mqh>

input int LongPeriod,ShortPeriod,ATRPeriod;
input int SLCoef;
input double TPCoef;
input ENUM_TIMEFRAMES ShortTimeframe;
input int positionCloseMin;
bool tradable = false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyDate myDate;
MyTrade myTrade();
MyPrice myPrice(ShortTimeframe, 3);
MyOrder myOrder(ShortTimeframe);
CurrencyStrength CS(ShortTimeframe, _Symbol);;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
  MyUtils myutils(60 * 20);
  myutils.Init();
  ciATR.Create(_Symbol,ShortTimeframe,ATRPeriod);
  return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
  Refresh();
  Check();
  ciATR.Refresh();

  myPrice.Refresh();

  double LongHighest = myPrice.Higest(0,LongPeriod);
  double LongLowest = myPrice.Lowest(0,LongPeriod);
  double ShortHighest = myPrice.Higest(2,ShortPeriod);
  double ShortLowest = myPrice.Lowest(2,ShortPeriod);

  double CenterLine = (LongHighest+LongLowest)/2;

  if(isBetween(myPrice.At(1).close,ShortHighest,myPrice.At(2).close))
    myTrade.signal = "buy";
  if(isBetween(myPrice.At(2).close,ShortLowest,myPrice.At(1).close))
    myTrade.signal = "sell";



  //myPosition.CloseAllPositionsInMinute(positionCloseMin);
  double PriceUnit = ciATR.Main(0)*TPCoef;
  if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions / 2 && myTrade.signal == "buy") {
    double SL  = LongLowest;
    double TP = myTrade.Ask + PriceUnit*TPCoef;
    if(myTrade.isInvalidTrade(SL, TP)) return;
    if(myPosition.isPositionInTPRange(PriceUnit,myPrice.At(0).close,POSITION_TYPE_BUY)) return;
    trade.Buy(myTrade.lot, NULL, myTrade.Ask, SL, TP, NULL);
  }

  if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions / 2 && myTrade.signal == "sell") {
    double SL  = LongHighest;
    double TP = myTrade.Bid - PriceUnit*TPCoef;
    if(myTrade.isInvalidTrade(SL, TP)) return;
    if(myPosition.isPositionInTPRange(PriceUnit,myPrice.At(0).close,POSITION_TYPE_SELL)) return;
    trade.Sell(myTrade.lot, NULL, myTrade.Bid, SL, TP, NULL);
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

  myTrade.CheckBalance();
  myTrade.CheckMarginLevel();

  if(myDate.isFridayEnd() || myDate.isYearEnd()) myTrade.istradable = false;

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
  //myTrade.CheckUntradableTime("01:00", "07:00");
  //myTrade.CheckTradableTime("00:00","07:00");
  //myTrade.CheckTradableTime("08:00", "14:00");
  //myTrade.CheckTradableTime("15:00","23:00");
  if(myOrder.wasOrderedInTheSameBar()) myTrade.istradable = false;
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
