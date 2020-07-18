//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
#include <Original\MyUtils.mqh>
#include <Original\MyTrade.mqh>
#include <Original\MyCalculate.mqh>
#include <Original\MyTest.mqh>
#include <Original\MyPrice.mqh>
#include <Original\MyPosition.mqh>
#include <Indicators\TimeSeries.mqh>
#include <Indicators\Oscilators.mqh>
#include <Trade\OrderInfo.mqh>
#include <Indicators\Trend.mqh>
CTrade trade;
MyPosition myPosition;
CiIchimoku ciIchimoku;

input int SenkouCri, KijunCri, TP;
input ENUM_TIMEFRAMES IchimokuTimeframe;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   MyUtils myutils();
   myutils.Init();
   ciIchimoku.Create(_Symbol, IchimokuTimeframe, 9, 26, 52);
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   MyTrade myTrade(0.1, false);
   MyPosition myPosition;
   myTrade.CheckFridayEnd();
   myTrade.CheckYearsEnd();
   if(!myTrade.istradable) {
      myPosition.CloseAllPositions(POSITION_TYPE_BUY);
      myPosition.CloseAllPositions(POSITION_TYPE_SELL);
   }

   myTrade.CheckBalance();
   myTrade.CheckSpread();
   if(!myTrade.istradable) {
      return;
   }

   ciIchimoku.Refresh();

   double Tenkan = ciIchimoku.TenkanSen(1);
   double Kijun = ciIchimoku.KijunSen(1);
   double SpanA = ciIchimoku.SenkouSpanA(1);
   double SpanB = ciIchimoku.SenkouSpanB(1);

   if( MathAbs(SpanA - SpanB) < SenkouCri * _Point) return;
   if(MathAbs(SpanA - SpanB) < KijunCri * _Point) return;

   if(Tenkan > Kijun && Kijun > SpanA && SpanA > SpanB) myTrade.signal = "buy";

   if(myPosition.Total < positions && myTrade.signal == "buy") {
      if(myTrade.isInvalidTrade(SpanA,myTrade.Ask + TP * _Point)) return;
      trade.Buy(myTrade.lot, NULL, myTrade.Ask, SpanA, myTrade.Ask + TP * _Point, NULL);
   }
}

double OnTester() {
   MyTest myTest;
   double result =  myTest.min_dd_and_mathsqrt_profit_trades_only_longs();
   return  result;
}
//+------------------------------------------------------------------+
