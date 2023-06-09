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
#include <Original\prices.mqh>
#include <Original\positions.mqh>
#include <Original\period.mqh>
#include <Original\account.mqh>
#include <Original\caluculate.mqh>
#include <Original\MyUtils.mqh>
#include <Original\MyTrade.mqh>
#include <Original\MyCalculate.mqh>
#include <Original\MyTest.mqh>
#include <Original\MyPrice.mqh>
#include <Original\MyPosition.mqh>
#include <Indicators\TimeSeries.mqh>
#include <Indicators\Oscilators.mqh>
#include <Indicators\Trend.mqh>
#include <Trade\OrderInfo.mqh>
COrderInfo cOrderInfo;
CTrade trade;
CiBands ciLongBand,ciShortBand;

input ENUM_TIMEFRAMES BandTimeframe;
input ENUM_APPLIED_PRICE BandAppliedPrice;

input double LongDeviation,ShortDeviation;

input int ShortBandPeriod,LongBandPeriod;
input double TPCoef,SLCoef;
bool tradable = false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPrice myPrice(BandTimeframe, 1);
MyPosition myPosition;
MyTrade myTrade(0.1, false);

// ATR, bottom,top個別
int OnInit() {
   MyUtils myutils(14100, 60 * 27);
   myutils.Init();
   ciLongBand.Create(_Symbol, BandTimeframe, LongBandPeriod, 0, LongDeviation, BandAppliedPrice);
   ciShortBand.Create(_Symbol, BandTimeframe, ShortBandPeriod, 0, ShortDeviation, BandAppliedPrice);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   myPrice.Refresh();
   myPosition.Refresh();
   myTrade.Refresh();
   ciLongBand.Refresh();
   ciShortBand.Refresh();
   myTrade.CheckSpread();
   
   if(!myTrade.istradable || !tradable) return;
   
   if(ciLongBand.Lower(0) > myPrice.getData(0).close && ciShortBand.Lower(0) > myPrice.getData(0).close){
      myTrade.signal = "sell";
   }
   else if(ciLongBand.Upper(0) < myPrice.getData(0).close && ciShortBand.Upper(0) < myPrice.getData(0).close){
      myTrade.signal = "buy";
   }
   
      if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions/2 && myTrade.signal=="buy")
     {
      double PriceUnit = ciLongBand.Upper(0) - ciShortBand.Base(0);
      trade.Buy(myTrade.lot,NULL,myTrade.Ask,myTrade.Ask-PriceUnit*SLCoef,myTrade.Ask+PriceUnit*TPCoef,NULL);
     }

   if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions/2 && myTrade.signal=="sell")
     {
      double PriceUnit = ciLongBand.Lower(0) - ciShortBand.Base(0);
      trade.Sell(myTrade.lot,NULL,myTrade.Bid,myTrade.Bid+PriceUnit*SLCoef,myTrade.Bid-PriceUnit*TPCoef,NULL);
     }
}

void OnTimer() {
   myPosition.Refresh();
   myTrade.Refresh();

   tradable = true;

   myTrade.CheckFridayEnd();
   myTrade.CheckYearsEnd();
   myTrade.CheckBalance();

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

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
