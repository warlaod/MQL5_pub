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
input int MACDLongPeriod,PricePeriod;
input ENUM_APPLIED_PRICE MacdPriceType;
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

CiMACD MACDLong,MACDShort;
CiATR ATR;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
  MyUtils myutils(60 * 27);
  myutils.Init();
  MACDLong.Create(_Symbol,Timeframe,12*MACDLongPeriod,26*MACDLongPeriod,9*MACDLongPeriod,MacdPriceType);
  MACDShort.Create(_Symbol,Timeframe,12,26,9,MacdPriceType);
  return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
  Refresh();
  Check();

  ATR.Refresh();
  MACDLong.Refresh();
  MACDShort.Refresh();

  myPosition.CloseAllPositionsInMinute(positionCloseMin);

  if(!myTrade.istradable || !tradable) return;

  double LongHistogram[2];
  double ShortHistogram[2];
  for(int i=0; i<2; i++) {
    LongHistogram[i] = MACDLong.Main(i) - MACDLong.Signal(i);
    ShortHistogram[i] = MACDShort.Main(i) - MACDShort.Signal(i);
  }

  if(LongHistogram[0] > 0 && MACDLong.Main(0) > 0) {
    myTrade.signal ="buybuy";
  } else if(LongHistogram[0] < 0 && MACDLong.Main(0) < 0) {
    myTrade.signal ="sellsell";
  }

  if(ShortHistogram[1] < 0 && ShortHistogram[0] > 0 && MACDShort.Main(0) < 0 && myTrade.signal == "buybuy") {
    myTrade.setSignal(ORDER_TYPE_BUY);
  } else if(ShortHistogram[1] > 0 && ShortHistogram[0] < 0 && MACDShort.Main(0) > 0 && myTrade.signal == "sellsell") {
    myTrade.setSignal(ORDER_TYPE_SELL);
  }

  double Highest = myPrice.Highest(0,PricePeriod);
  double Lowest = myPrice.Lowest(0,PricePeriod);

  double PriceUnit = 10 * _Point;
  if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions / 2 )
    if(myPosition.isPositionInRange(Highest + PriceUnit * TPCoef - myTrade.Ask,POSITION_TYPE_BUY)) return;
  myTrade.Buy(Lowest - PriceUnit*SLCoef, Highest + PriceUnit * TPCoef);
  if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions / 2 )
    if(myPosition.isPositionInRange(Lowest - PriceUnit * TPCoef + myTrade.Bid,POSITION_TYPE_SELL)) return;
  myTrade.Sell(Highest + PriceUnit * SLCoef, Lowest - PriceUnit * TPCoef);


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
