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
#include <Generic\Interfaces\IComparable.mqh>

input int PricePeriod,BandPeriod,BandWidthPeriod,TrendPeriod,ATRPeriod;
input int SLCoef, TPCoef;
input double BandWidthDiffCri;
input int BandWidthTop,BandWidthBottom;
input int BandWidthCri,TrendCri;
input ENUM_TIMEFRAMES BandTimeframe;
input int positionCloseMin;
bool tradable = false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyTrade myTrade();
MyPrice myPrice(BandTimeframe, 3);
MyOrder myOrder(BandTimeframe);
CurrencyStrength CS(BandTimeframe, _Symbol);;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
  MyUtils myutils(60 * 27);
  myutils.Init();
  ciBands.Create(_Symbol,BandTimeframe,BandPeriod,0,3,PRICE_CLOSE);
  return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
  Refresh();
  Check();

  ciBands.Refresh();
  ciATR.Refresh();
  myPrice.Refresh();


  //myPosition.CloseAllPositionsInMinute(positionCloseMin);

  CArrayDouble BandWidth;
  for(int i=0; i<BandWidthPeriod; i++) {
    BandWidth.Add(ciBands.Upper(i)- ciBands.Lower(i));
  }

  if(!myTrade.istradable || !tradable) return;

  if(isBetween(BandWidthTop*_Point,BandWidth[0],BandWidthBottom*_Point)) return;
  if(BandWidth[0] / BandWidth[BandWidth.Minimum(0,TrendPeriod-1)] > BandWidthDiffCri) return;

  if(myPrice.At(1).high > ciBands.Upper(1) && myPrice.At(1).close < ciBands.Upper(1)) myTrade.signal = "sell";
  else if(myPrice.At(1).low < ciBands.Upper(1) && myPrice.At(1).close > ciBands.Lower(1)) myTrade.signal = "buy";

  double PriceUnit = 10 * _Point;
  if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions / 2 && myTrade.signal == "buy") {
    if(myTrade.isInvalidTrade(myPrice.At(1).low, ciBands.Base(0))) return;
    trade.Buy(myTrade.lot, NULL, myTrade.Ask, myPrice.At(1).low, ciBands.Base(0), NULL);
  }

  if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions / 2 && myTrade.signal == "sell") {
    if(myTrade.isInvalidTrade(myPrice.At(1).high, ciBands.Base(0))) return;
    trade.Sell(myTrade.lot, NULL, myTrade.Bid, myPrice.At(1).high, ciBands.Base(0), NULL);
  }

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer() {
  myPosition.Refresh();
  myTrade.Refresh();

  tradable = true;

  myTrade.CheckFridayEnd();
  myTrade.CheckYearsEnd();
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
  myTrade.CheckUntradableTime("01:00", "07:00");
//myTrade.CheckTradableTime("00:00","07:00");
  //myTrade.CheckTradableTime("08:00", "14:00");
 //myTrade.CheckTradableTime("14:00","24:00");
  if(myOrder.wasOrderedInTheSameBar()) myTrade.istradable = false;
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
