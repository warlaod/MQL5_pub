//+------------------------------------------------------------------+
//|                                                     templete.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"





#include <Trade\Trade.mqh>
#include <Original\prices.mqh>
#include <Original\positions.mqh>
#include <Original\period.mqh>
#include <Original\account.mqh>
CTrade trade;
MqlDateTime dt;
input int indperiod1 = 5;
input int indparam1 = 32;
input int positions = 1;
input double TPbuy = 1.0010;
input double SLbuy = 1.0020;
input double TPsell = 1.0021;
input double SLsell = 1.0000;
double lot = 0.10;
double  Bid,Ask;
string signal;
ENUM_TIMEFRAMES Indperiod1;


input int indperiod2;
ENUM_TIMEFRAMES Indperiod2;
input int indperiod3;
ENUM_TIMEFRAMES Indperiod3;
double Osma_fast[],Osma_slow[];
int OsmaIndicator_fast,OsmaIndicator_slow;
input int pricetype;

input int indperiod4;
ENUM_TIMEFRAMES Indperiod4;
double ATR_val[];
input int param_ATR;
int ATRindicator;
input double  ATR_criterion;

input int spread;

input int traderange;
input int secondsrange;
input int stopcount;

input int denominator;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   Indperiod1 = Timeframe(indperiod1);
   
   Indperiod2 = Timeframe(indperiod2);
   ArraySetAsSeries(Osma_fast,true);
   
   OsmaIndicator_fast = iOsMA(_Symbol,Indperiod2,12,26,9,pricetype);
   
   Indperiod4 = Timeframe(indperiod4);
   ATRindicator = iATR(_Symbol,Indperiod4,param_ATR);
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(isTooBigSpread(spread))
     {
      return;
     }
   
   lot = SetLot(denominator);
   
   if(StopLossCount(traderange,secondsrange) >stopcount){
      return;
   };
   

   Bid=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
   Ask=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);

   double HighestPrice = HighestPrice(_Symbol,Indperiod1,indparam1);
   double LowestPrice = LowestPrice(_Symbol,Indperiod1,indparam1);


   
   CopyBuffer(OsmaIndicator_fast,0,0,1,Osma_fast);

   if(HighestPrice == EMPTY_VALUE || LowestPrice == EMPTY_VALUE)
     {
      return;
     }
     
   if(Osma_fast[0] == EMPTY_VALUE)
     {
      return;
     }
     
     
   if( Osma_fast[0] > 0 )
     {
      signal = "buy";
      CloseAllSellPositions();
     }
   else if(Osma_fast[0] < 0 )
     {
      signal = "sell";
      CloseAllBuyPositions();
     }



      if(signal == "buy" && EachPositionsTotal("buy") < positions/2)
        {
         if((HighestPrice*TPbuy - Ask) > 20*_Point && (Ask - LowestPrice*SLbuy) > 9*_Point)
           {
            trade.Buy(lot,NULL,Ask,LowestPrice*SLbuy,HighestPrice*TPbuy,NULL);
           }
        }

      if(signal == "sell" && EachPositionsTotal("sell") < positions/2)
        {
         if((Bid -LowestPrice*TPsell) > 20*_Point  && (HighestPrice*SLsell- Bid) > 9*_Point)
           {
            trade.Sell(lot,NULL,Bid,HighestPrice*SLsell,LowestPrice*TPsell,NULL);
           }
        }



  }

//+------------------------------------------------------------------+
double OnTester()
  {
   double  param = 0.0;

//  Balance max + min Drawdown + Trades Number:
   double  balance = TesterStatistics(STAT_PROFIT);
   double  min_dd = TesterStatistics(STAT_BALANCEDD_PERCENT)*100;
   double average_profit = 0;
   double average_loss = 0;
   double  trades_number = TesterStatistics(STAT_TRADES);
   double  profit_trades_number = TesterStatistics(STAT_PROFIT_TRADES);
   double win_rate = 0;
   double short_long_ratio = 0;
   double long_trades = TesterStatistics(STAT_LONG_TRADES);
   double short_trades = TesterStatistics(STAT_SHORT_TRADES);
   if(long_trades == 0 || short_trades == 0)
     {
      return -999999999;
     }
   if(min_dd == 0 )
     {
      return -999999999;
     }

   if(balance > 0){
   param = MathSqrt(balance)*(1/min_dd);
   }else{
   param = -MathSqrt(-balance) /(1/min_dd);
   }




//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   return(param);
  }
//+------------------------------------------------------------------+
