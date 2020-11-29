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
input int ATRPeriod;
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
CiIchimoku Ichimoku;
CiATR ATR;
int OnInit() {
  MyUtils myutils(60 * 27);
  myutils.Init();
  Ichimoku.Create(_Symbol,Timeframe,9,26,52);
  ATR.Create(_Symbol,Timeframe,ATRPeriod);
  return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
  Refresh();
  Check();
  Ichimoku.Refresh();
  myPrice.Refresh();
  ATR.Refresh();
  //myPosition.CloseAllPositionsInMinute(positionCloseMin);
  
  if(myPrice.At(1).close > Ichimoku.SenkouSpanA(1)) myPosition.CloseAllPositions(POSITION_TYPE_SELL);
  if(myPrice.At(1).close < Ichimoku.SenkouSpanA(1)) myPosition.CloseAllPositions(POSITION_TYPE_BUY);
  
  if(!myTrade.istradable || !tradable) return;

  if(isBetween(Ichimoku.SenkouSpanA(1),Ichimoku.SenkouSpanB(1),Ichimoku.KijunSen(1))) {
    if(Ichimoku.KijunSen(1) > Ichimoku.TenkanSen(1) && myPrice.At(1).high < Ichimoku.SenkouSpanB(1))
      myTrade.setSignal(ORDER_TYPE_SELL);
  } else if(isBetween(Ichimoku.KijunSen(1),Ichimoku.SenkouSpanB(1),Ichimoku.SenkouSpanA(1))) {
    if(Ichimoku.KijunSen(1) < Ichimoku.TenkanSen(1) && myPrice.At(1).low > Ichimoku.SenkouSpanB(1))
      myTrade.setSignal(ORDER_TYPE_BUY);
  }


  double PriceUnit = ATR.Main(0);
  if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions / 2 ) myTrade.Buy(Ichimoku.SenkouSpanA(0), myTrade.Ask + PriceUnit * TPCoef);
  if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions / 2 ) myTrade.Sell(Ichimoku.SenkouSpanA(0), myTrade.Bid - PriceUnit * TPCoef);


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
