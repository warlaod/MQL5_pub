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
#include <Original\MySymbolAccount.mqh>
#include <Original\MyTest.mqh>
#include <Original\MyPrice.mqh>
#include <Original\MyPosition.mqh>
#include <Original\MyOrder.mqh>
#include <Original\MyHistory.mqh>
#include <Original\MyCHart.mqh>
#include <Original\MyFractal.mqh>
#include <Original\Optimization.mqh>
#include <Indicators\TimeSeries.mqh>
#include <Indicators\Oscilators.mqh>
#include <Indicators\Trend.mqh>
#include <Indicators\BillWilliams.mqh>
#include <Indicators\Volumes.mqh>
#include <Trade\PositionInfo.mqh>
#include <ChartObjects\ChartObjectsLines.mqh>

int ADXMinusCri = 26;
int ADXPlusCri = 4;
double SellLotDiv = 0.9;
double PriceUnitCri = 6.75;
int TrailPeriod = 1;
int SLPeriod = 22;
int TrailStart = 0;
mis_MarcosTMP timeFrame = _H8;
mis_MarcosTMP trailTimeframe = _H1;
mis_MarcosTMP slTimeframe = _H4;
ENUM_TIMEFRAMES Timeframe = defMarcoTiempo(timeFrame);
ENUM_TIMEFRAMES TrailTimeframe = defMarcoTiempo(trailTimeframe);
ENUM_TIMEFRAMES SLTimeframe = defMarcoTiempo(slTimeframe);
bool tradable = false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyTrade myTrade();
MyDate myDate(Timeframe);
MyPrice myPrice(PERIOD_MN1), myTrailPrice(TrailTimeframe), mySLPrice(SLTimeframe);
MyHistory myHistory(Timeframe);
MyOrder myOrder(myDate.BarTime);
CurrencyStrength CS(Timeframe, 1);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CiADX ADX;
MyChart Chart;
MySymbolAccount SA;
int OnInit() {
   MyUtils myutils(60 * 1);
   myutils.Init();
   myTrade.SetExpertMagicNumber(MagicNumber);
   ADX.Create(_Symbol, Timeframe, 18);
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double PriceUnit = 10 * MathPow(2, PriceUnitCri);
void OnTick() {
   IsCurrentTradable = true;

   //myOrder.Refresh();
   //myPosition.CloseAllPositionsInMinute();


   myPosition.Refresh();
   double TrailLowest = myTrailPrice.Lowest(TrailStart, TrailPeriod);
   double TrailHighest = myTrailPrice.Highest(TrailStart, TrailPeriod);
   myPosition.CheckTargetPriceProfitableForTrailings(POSITION_TYPE_BUY, TrailLowest, 40 * pipsToPrice);
   myPosition.CheckTargetPriceProfitableForTrailings(POSITION_TYPE_SELL, TrailHighest, 40 * pipsToPrice);
   myPosition.Trailings(POSITION_TYPE_BUY, TrailLowest);
   myPosition.Trailings(POSITION_TYPE_SELL, TrailHighest);

   Check();
   if(!IsCurrentTradable || !IsTradable) return;

   myTrade.Refresh();
   myPosition.Refresh();
   if(!myPosition.isPositionInRange(POSITION_TYPE_BUY, PriceUnit)) {
      myTrade.ForceBuy(0, 100000);
   }
   ADX.Refresh();
   if(!myPosition.isPositionInRange(POSITION_TYPE_SELL, PriceUnit)) {
      if(ADX.Minus(0) > 20) {
         if(ADX.Main(0) < ADXMinusCri || !isRising(ADX, 2)) return;
         myTrade.ForceSell(mySLPrice.Highest(1, SLPeriod), 0, SellLot());
      }
   }
   myPosition.Refresh();
   if(BuyLot() != 0) {
      if(ADX.Plus(0) > 20) {
         if(ADX.Main(0) < ADXPlusCri || !isRising(ADX, 1)) return;
         myTrade.ForceBuy(0, 100000, BuyLot());
      }
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer() {
   IsTradable = true;
   if(myTrade.isLowerBalance() || myTrade.isLowerMarginLevel()) {
      Print("EA stopped trading because of lower balance or lower margin level  ");
      IsTradable = false;
   }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double OnTester() {
   MyTest myTest;
   double result =  myTest.min_dd_and_mathsqrt_trades_without_balance();
   return  result;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Check() {
   if(SA.isOverSpread()) IsCurrentTradable = false;
   myDate.Refresh();
   if(myDate.isMondayStart()) IsCurrentTradable = false;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double SellLot() {
   double lot = 0;
   for(int i = 0; i < myPosition.BuyTickets.Total(); i++) {
      myPosition.SelectByTicket(myPosition.BuyTickets.At(i));
      lot += myPosition.Volume();
   }
   for(int i = 0; i < myPosition.SellTickets.Total(); i++) {
      myPosition.SelectByTicket(myPosition.SellTickets.At(i));
      lot -= myPosition.Volume();
   }
   lot = NormalizeDouble(lot / SellLotDiv, SA.LotDigits);
   if(lot < SA.MinLot) lot = SA.MinLot;
   else if(lot > SA.MaxLot) lot = SA.MaxLot;
   return lot;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double BuyLot() {
   double lot = 0;
   for(int i = 0; i < myPosition.SellTickets.Total(); i++) {
      myPosition.SelectByTicket(myPosition.SellTickets.At(i));
      lot += myPosition.Volume();
   }
   for(int i = 0; i < myPosition.BuyTickets.Total(); i++) {
      myPosition.SelectByTicket(myPosition.BuyTickets.At(i));
      lot -= myPosition.Volume();
   }
   lot = NormalizeDouble(lot, SA.LotDigits);
   if(lot < SA.MinLot) lot = 0;
   else if(lot > SA.MaxLot) lot = SA.MaxLot;
   return lot;
}
//+------------------------------------------------------------------+
