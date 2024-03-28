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
CiMA ciMALong, ciMAMiddle, ciMAShort;
CiBands ciBands;
CiMACD ciMacdLong, ciMacdShort;
CiStochastic ciStochastic;
#include <Generic\Interfaces\IComparable.mqh>

input int TPCoef, SLCoef;
input ENUM_TIMEFRAMES MAShortTimeframe, CSTimeframe;
input int LongMiddleCri,PriceCount;
input int positionCloseMin;
bool tradable = false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyTrade myTrade();
MyPrice myPrice(MAShortTimeframe, 10);
MyOrder myOrder(MAShortTimeframe);
CurrencyStrength CS(CSTimeframe, 1);;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
  MyUtils myutils(60 * 27);
  myutils.Init();

  ciMAShort.Create(_Symbol, MAShortTimeframe, 10, 0, MODE_SMA, PRICE_CLOSE);
  ciMAMiddle.Create(_Symbol, MAShortTimeframe, 40, 0, MODE_SMA, PRICE_CLOSE);
  ciMALong.Create(_Symbol, MAShortTimeframe, 160, 0, MODE_SMA, PRICE_CLOSE);
  return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
  Refresh();
  ciMAShort.Refresh();
  ciMALong.Refresh();
  ciMAMiddle.Refresh();
  Check();


  //if(MathAbs(ciMALong.Main(0) - ciMAMiddle.Main(0)) < LongMiddleCri*_Point) return;




  //myPosition.CloseAllPositionsInMinute(positionCloseMin);

  if(!myTrade.istradable || !tradable) return;

  if(isBetween(ciMAMiddle.Main(0),ciMAShort.Main(0),ciMALong.Main(0))) {
    if(myPrice.At(1).low > myPrice.At(0).low && myPrice.At(1).high > myPrice.At(0).high) {
      if(myPrice.Lowest(1,PriceCount) > myPrice.At(0).low)
        myTrade.signal = "sell";
    }
  } else if(isBetween(ciMALong.Main(0),ciMAShort.Main(0),ciMAMiddle.Main(0))) {
    if(myPrice.At(1).low < myPrice.At(0).low && myPrice.At(1).high < myPrice.At(0).high) {
      if(myPrice.Higest(1,PriceCount) < myPrice.At(0).high)
        myTrade.signal = "buy";
    }
  }

  double PriceUnit = 10 * _Point;
  if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions / 2 && myTrade.signal == "buy") {
    double SL  = ciMAMiddle.Main(0);
    double TP = ciMALong.Main(0);
    if(myTrade.isInvalidTrade(SL, TP)) return;
    trade.Buy(myTrade.lot, NULL, myTrade.Ask, SL, TP, NULL);
  }

  if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions / 2 && myTrade.signal == "sell") {
    double SL  = ciMAMiddle.Main(0);
    double TP = ciMALong.Main(0);
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
  myPrice.Refresh();
  myOrder.Refresh();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Check() {
  myTrade.CheckSpread();
  //myTrade.CheckUntradableTime("01:00","07:00");
  //myTrade.CheckTradableTime("00:00","07:00");
  //myTrade.CheckTradableTime("08:00", "14:00");
  //myTrade.CheckTradableTime("14:00","24:00");
  if(myOrder.wasOrderedInTheSameBar()) myTrade.istradable = false;
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
