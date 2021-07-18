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

input int StoBuyCri,StoSellCri;
input double SellLotDiv = 1;
input double buyTP = 4.25;
input int TrailPeriod = 1;
input int k;
input int TrailStart = 1;
input mis_MarcosTMP timeFrame = _H8;
input mis_MarcosTMP trailTimeframe = _H1;
ENUM_TIMEFRAMES Timeframe = defMarcoTiempo(timeFrame);
ENUM_TIMEFRAMES TrailTimeframe = defMarcoTiempo(trailTimeframe);
bool tradable = false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPosition myPosition;
MyTrade myTrade();
MyDate myDate(Timeframe);
MyPrice myPrice(PERIOD_MN1), myTrailPrice(TrailTimeframe);
MyHistory myHistory(Timeframe);
MyOrder myOrder(myDate.BarTime);
CurrencyStrength CS(Timeframe, 1);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CiStochastic Sto;
MySymbolAccount SA;
CArrayDouble OpenPrices;
int OnInit()
  {
   MyUtils myutils(60 * 1);
   myutils.Init();
   myTrade.SetExpertMagicNumber(MagicNumber);
   Sto.Create(_Symbol, Timeframe, k, 3, 3, MODE_EMA, STO_LOWHIGH);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double BuyTP = 10 * MathPow(2, buyTP);
void OnTick()
  {
   IsCurrentTradable = true;

//myOrder.Refresh();
//myPosition.CloseAllPositionsInMinute();


   myPosition.Refresh();
   double TrailHighest = myTrailPrice.Highest(TrailStart, TrailPeriod);
   myPosition.CheckTargetPriceProfitableForTrailings(POSITION_TYPE_SELL, TrailHighest, 40 * pipsToPrice);
   myPosition.Trailings(POSITION_TYPE_SELL, TrailHighest);

   Check();
   if(!IsCurrentTradable || !IsTradable)
      return;

   myTrade.Refresh();

   //double Min;
   //int TicketTotal = myPosition.BuyTickets.Total();
   //for(int i = 0; i < TicketTotal; i++)
   //  {
   //   myPosition.SelectByTicket(myPosition.BuyTickets.At(i));
   //   double OpenPrice = myPosition.PriceOpen();
   //   if(i == 0)
   //     {
   //      Min = OpenPrice;
   //     }
   //   else
   //     {
   //      if(Min > OpenPrice)
   //         Min = OpenPrice;
   //     }
   //  }

   Sto.Refresh();
   if(!myPosition.isPositionInRange(POSITION_TYPE_BUY, BuyTP))
     {
      if(isGoldenCross(Sto, 1))
        {
         if(Sto.Signal(1) < StoBuyCri)
            myTrade.ForceBuy(0, myTrade.Ask + BuyTP);
        }
     }
     
     if(isDeadCross(Sto, 1))
        {
         if(Sto.Signal(1) > StoSellCri)
            myTrade.ForceSell(myTrade.Bid + BuyTP, 0,SellLot());
        }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer()
  {
   IsTradable = true;
   if(myTrade.isLowerBalance() || myTrade.isLowerMarginLevel())
     {
      Print("EA stopped trading because of lower balance or lower margin level  ");
      IsTradable = false;
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double OnTester()
  {
   MyTest myTest;
   double result =  myTest.min_dd_and_mathsqrt_trades_without_balance();
   return  result;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Check()
  {
   if(SA.isOverSpread())
      IsCurrentTradable = false;
   myDate.Refresh();
   if(myDate.isMondayStart())
      IsCurrentTradable = false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double SellLot()
  {
   double lot = 0;
   for(int i = 0; i < myPosition.BuyTickets.Total(); i++)
     {
      myPosition.SelectByTicket(myPosition.BuyTickets.At(i));
      lot += myPosition.Volume();
     }
   for(int i = 0; i < myPosition.SellTickets.Total(); i++)
     {
      myPosition.SelectByTicket(myPosition.SellTickets.At(i));
      lot -= myPosition.Volume();
     }
   lot = NormalizeDouble(lot / SellLotDiv, SA.LotDigits);
   if(lot < SA.MinLot || lot < 0.1)
      lot = 0;
   else
      if(lot > SA.MaxLot)
         lot = SA.MaxLot;
   return lot;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double BuyLot()
  {
   double lot = 0;
   for(int i = 0; i < myPosition.SellTickets.Total(); i++)
     {
      myPosition.SelectByTicket(myPosition.SellTickets.At(i));
      lot += myPosition.Volume();
     }
   for(int i = 0; i < myPosition.BuyTickets.Total(); i++)
     {
      myPosition.SelectByTicket(myPosition.BuyTickets.At(i));
      lot -= myPosition.Volume();
     }
   lot = NormalizeDouble(lot, SA.LotDigits);
   if(lot < SA.MinLot)
      lot = 0;
   else
      if(lot > SA.MaxLot)
         lot = SA.MaxLot;
   return lot;
  }
//+------------------------------------------------------------------+
