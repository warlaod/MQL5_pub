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

input int PricePeriod;
input int SLCoef, TPCoef;
input ENUM_TIMEFRAMES MACDTimeframe;
input int MACDPeriodLong,HistgramPeriod;
input int positionCloseMin;
bool tradable = false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyDate myDate;
MyTrade myTrade();
MyPrice myPrice(MACDTimeframe, 2);
MyOrder myOrder(MACDTimeframe);
CurrencyStrength CS(MACDTimeframe, _Symbol);;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
  MyUtils myutils(60 * 20);
  myutils.Init();
  ciShortMACD.Create(_Symbol,MACDTimeframe,12,26,9,PRICE_CLOSE);
  return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
  Refresh();
  Check();

  ciShortMACD.Refresh();
  ciLongMACD.Refresh();
  myPrice.Refresh();


  //myPosition.CloseAllPositionsInMinute(positionCloseMin);

  CArrayDouble LongMACDHist,ShortMACDHist;
  for(int i=0; i<HistgramPeriod; i++) {
    LongMACDHist.Add(ciLongMACD.Main(i)-ciLongMACD.Signal(i));
    ShortMACDHist.Add(ciShortMACD.Main(i)-ciShortMACD.Signal(i));
  }

  if(ShortMACDHist.At(2) < 0 && ShortMACDHist.At(1) > 0) myPosition.CloseAllPositions(POSITION_TYPE_SELL);
  if(ShortMACDHist.At(2) > 0 && ShortMACDHist.At(1) < 0) myPosition.CloseAllPositions(POSITION_TYPE_BUY);

  if(!myTrade.istradable || !tradable) return;



  if(ShortMACDHist.At(0) > 0) {
    if(isBetween(ciShortMACD.Main(0),ciShortMACD.Main(1),ciShortMACD.Main(2)))
      myTrade.signal = "buy";
  }

  if(ShortMACDHist.At(0) < 0) {
    if(isBetween(ciShortMACD.Main(2),ciShortMACD.Main(1),ciShortMACD.Main(0)))
      myTrade.signal = "sell";
  }

  double PriceUnit = 10 * _Point;
  if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions / 2 && myTrade.signal == "buy") {
    double SL  = myPrice.Lowest(0,PricePeriod);
    double TP = myTrade.Ask + PriceUnit*TPCoef;
    if(myTrade.isInvalidTrade(SL, TP)) return;
    trade.Buy(myTrade.lot, NULL, myTrade.Ask, SL, TP, NULL);
  }

  if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions / 2 && myTrade.signal == "sell") {
    double SL  = myPrice.Higest(0,PricePeriod);
    double TP = myTrade.Bid - PriceUnit*TPCoef;
    if(myTrade.isInvalidTrade(SL, TP)) return;
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
