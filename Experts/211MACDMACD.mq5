//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
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
#include <Indicators\Volumes.mqh>
CTrade trade;
CiMACD ciLongMACD, ciShortMACD;
CiATR ciATR;
input ENUM_TIMEFRAMES Timeframe, MacdLongTimeframe;
input int ATRPeriod;
bool tradable = false;

input double TPCoef,SLCoef;
//+-------------------------

MyPosition myPosition;
MyTrade myTrade();
MyDate myDate();
MyPrice myPrice(Timeframe, 3);
MyOrder myOrder(Timeframe);
CurrencyStrength CS(Timeframe, 1);

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   MyUtils myutils(60 * 27);
   myutils.Init();
   trade.SetExpertMagicNumber(MagicNumber);

   ciLongMACD.Create(_Symbol, MacdLongTimeframe, 12, 26, 9, PRICE_CLOSE);
   ciShortMACD.Create(_Symbol, Timeframe, 12, 26, 9, PRICE_CLOSE);
   ciATR.Create(_Symbol, MacdLongTimeframe, ATRPeriod);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   if(Timeframe >= MacdLongTimeframe) return;
   Refresh();
   Check();

   //myPosition.CloseAllPositionsInMinute();
   if(!myTrade.istradable || !tradable) return;

   ciLongMACD.Refresh();
   ciShortMACD.Refresh();
   ciATR.Refresh();
   myPrice.Refresh();

   double LongHistogram[2];
   double ShortHistogram[2];
   for(int i = 0; i < 2; i++) {
      LongHistogram[i] = ciLongMACD.Main(i) - ciLongMACD.Signal(i);
      ShortHistogram[i] = ciShortMACD.Main(i) - ciShortMACD.Signal(i);
   }

   if(LongHistogram[0] > 0 && ciLongMACD.Main(0) > 0) {
      myTrade.signal = "buybuy";
   } else if(LongHistogram[0] < 0 && ciLongMACD.Main(0) < 0) {
      myTrade.signal = "sellsell";
   }

   if(ShortHistogram[1] < 0 && ShortHistogram[0] > 0 && ciShortMACD.Main(0) < 0 && myTrade.signal == "buybuy") {
      myTrade.setSignal(ORDER_TYPE_BUY);
   } else if(ShortHistogram[1] > 0 && ShortHistogram[0] < 0 && ciShortMACD.Main(0) > 0 && myTrade.signal == "sellsell") {
      myTrade.setSignal(ORDER_TYPE_SELL);
   }

   double PriceUnit = ciATR.Main(0);
   if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions / 2 ) myTrade.Buy(myPrice.Lowest(0,10), myTrade.Ask + PriceUnit * TPCoef);
   if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions / 2 ) myTrade.Sell(myPrice.Highest(0,10), myTrade.Bid - PriceUnit * TPCoef);


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
   double result =  myTest.PROM();
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
   //myTrade.CheckSpread();
   //myDate.isInTime("01:00", "07:00");
   if(myOrder.wasOrderedInTheSameBar()) myTrade.istradable = false;
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
