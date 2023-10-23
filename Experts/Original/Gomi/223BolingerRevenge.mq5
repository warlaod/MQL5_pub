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
#include <Original\Optimization.mqh>
#include <Indicators\TimeSeries.mqh>
#include <Indicators\Oscilators.mqh>
#include <Indicators\Trend.mqh>
#include <Indicators\BillWilliams.mqh>
#include <Indicators\Volumes.mqh>

input double SLCoef, TPCoef;
input mis_MarcosTMP timeFrame, stoctimeFrame;
input int BandPeriod;
input double Dev;
ENUM_TIMEFRAMES Timeframe = defMarcoTiempo(timeFrame);
ENUM_TIMEFRAMES StocTimeframe = defMarcoTiempo(stoctimeFrame);
bool tradable = false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyTrade myTrade();
MyDate myDate();
MyPrice myPrice(Timeframe, 7);
MyOrder myOrder(Timeframe);
CurrencyStrength CS(Timeframe, 1);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CiBands Band;
CiStochastic Stoc;
int OnInit() {
   MyUtils myutils(60 * 1);
   myutils.Init();

   Band.Create(_Symbol, Timeframe, BandPeriod, 0, Dev, PRICE_CLOSE);
   Stoc.Create(_Symbol, StocTimeframe, 5, 3, 3, MODE_EMA, STO_LOWHIGH);
   
   if(Timeframe <= StocTimeframe) return(INIT_PARAMETERS_INCORRECT);

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   

   Refresh();
   Check();
   Band.Refresh();
   Stoc.Refresh();
   myPrice.Refresh();

   //myPosition.CloseAllPositionsInMinute();
   if(!myTrade.istradable || !tradable) return;

   if(myPrice.At(0).high > Band.Upper(0)) {
      for(int i = 1; i <= 4; i++) {
         if(myPrice.At(i).high > Band.Upper(i)) return;
      }
      if(isDeadCross(Stoc.Main(1), Stoc.Signal(1), Stoc.Main(0), Stoc.Signal(0)))
         myTrade.setSignal(ORDER_TYPE_BUY);
   }

   if(myPrice.At(0).low < Band.Lower(0)) {
      for(int i = 1; i <= 4; i++) {
         if(myPrice.At(i).low < Band.Lower(i)) return;
      }
      if(isGoldenCross(Stoc.Main(1), Stoc.Signal(1), Stoc.Main(0), Stoc.Signal(0)))
         myTrade.setSignal(ORDER_TYPE_SELL);
   }

   double PriceUnit = Band.Upper(0) - Band.Base(0);
   if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions / 2 ) {
      myTrade.Buy(myTrade.Ask - PriceUnit * SLCoef, Band.Base(0));
   }
   if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions / 2 ) {
      myTrade.Sell(myTrade.Bid + PriceUnit * SLCoef, Band.Base(0));
   }


}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer() {
   myPosition.Refresh();
   myTrade.Refresh();
   myDate.Refresh();
   myOrder.Refresh();

   tradable = true;

   //if(!myDate.isInTime("01:00", "07:00")) myTrade.istradable = false;
   if(myOrder.wasOrderedInTheSameBar()) myTrade.istradable = false;

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
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Check() {
   //myTrade.CheckSpread();

}


//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
