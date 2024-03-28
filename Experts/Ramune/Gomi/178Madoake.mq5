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
#include <Original\MyCalculate.mqh>
#include <Original\MyTest.mqh>
#include <Original\MyPrice.mqh>
#include <Original\MyDate.mqh>
#include <Original\MyPosition.mqh>
#include <Indicators\TimeSeries.mqh>
#include <Indicators\Oscilators.mqh>
#include <Indicators\Trend.mqh>
#include <Trade\OrderInfo.mqh>
#include <Arrays\ArrayDouble.mqh>
#include <Indicators\BillWilliams.mqh>
#include <Arrays\ArrayDouble.mqh>
CTrade trade;
CiOsMA ciOsma;
CiBands ciBands;
CiStochastic ciStochastic;
input int TPCoef, SLCoef;
input int MondayCri;
input int closeHour, MondayTradeCri;
input int StohasticPeriod;
input ENUM_TIMEFRAMES LongPriceTimeframe, ShortPriceTimeframe, StochasticTimeframe;
bool tradable = false;

datetime lastStopLossTime;
int MondayTrades = 0;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyTrade myTrade();
MyPrice myWeekPrice(PERIOD_W1, 3);
MyPrice myShortPrice(ShortPriceTimeframe, 3);
MyDate myDate;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   MyUtils myutils(60 * 27);
   myutils.Init();
   trade.SetExpertMagicNumber(MagicNumber);
   ciStochastic.Create(_Symbol, StochasticTimeframe, StohasticPeriod, 3, 3, MODE_SMA, STO_LOWHIGH);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   myPosition.Refresh();
   myTrade.Refresh();
   myWeekPrice.Refresh();
   myShortPrice.Refresh();
   myTrade.CheckSpread();


   myDate.Refresh();

   myTrade.CheckSpread();
   if(!myTrade.istradable || !tradable) return;

   {
      if(myDate.dt.day_of_week == MONDAY && myDate.dt.hour < closeHour && MondayTrades < MondayTradeCri) {
         double Mado = myWeekPrice.getData(0).open - myWeekPrice.getData(1).close;
         ciStochastic.Refresh();
         if(MathAbs(Mado) < MondayCri * _Point) return;
         double dwa = ciStochastic.Signal(1);
         double dadw = ciStochastic.Main(2);
         if(Mado > 0) {
            if(ciStochastic.Signal(2) > 80 && ciStochastic.Main(2) > ciStochastic.Signal(2) && ciStochastic.Main(1) < ciStochastic.Signal(1))
               myTrade.signal = "MondaySell";
         }
         if(Mado < 0) {
            if(ciStochastic.Signal(2) < 20 && ciStochastic.Main(2) < ciStochastic.Signal(2) && ciStochastic.Main(1) > ciStochastic.Signal(1))
               myTrade.signal = "MondayBuy";
         }
      } else if(myDate.dt.day_of_week == TUESDAY) {
         MondayTrades = 0;
      }

      if(myDate.dt.day_of_week == MONDAY &&  myDate.dt.hour == closeHour) {
         myPosition.CloseAllPositions(POSITION_TYPE_BUY);
         myPosition.CloseAllPositions(POSITION_TYPE_SELL);
      }

      double PriceUnit = 10 * _Point;
      double dwadawdawd = myWeekPrice.getData(1).close;
      if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions / 2 && myTrade.signal == "MondayBuy" ) {
         if(myTrade.isInvalidTrade(myTrade.Ask - PriceUnit * SLCoef,  myWeekPrice.getData(1).close)) return;
         trade.Buy(myTrade.lot, NULL, myTrade.Ask, myTrade.Ask - PriceUnit * SLCoef,  myWeekPrice.getData(1).close, NULL);
         MondayTrades++;
      }
      if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions / 2 && myTrade.signal == "MondaySell") {
         if(myTrade.isInvalidTrade(myTrade.Bid + PriceUnit * SLCoef,  myWeekPrice.getData(1).close)) return;
         trade.Sell(myTrade.lot, NULL, myTrade.Bid, myTrade.Bid + PriceUnit * SLCoef,  myWeekPrice.getData(1).close, NULL);
         MondayTrades++;
      }
   }



}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer() {
   myPosition.Refresh();
   myTrade.Refresh();

   tradable = true;
   MyDate myDate();
   myDate.Refresh();
   if(myDate.isYearEnd() || myDate.isYearEnd()) myTrade.istradable = false;
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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
