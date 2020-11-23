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

string signal;
input int span1 = 14;
input double deviation = 0.1;
input int indperiod1 = 0;
input int pricetype = 0;
input int positions = 1;
input double TPbuy = 1.2;
input double SLbuy = 0.5;
input double TPsell = 1.2;
input double SLsell = 0.5;
double lot = 0.10;
MqlDateTime dt;
int Indicator;
double  Bid,Ask;
ENUM_TIMEFRAMES Indperiod1;
double high[],low[];

double myRSIArray[];
int RSIIndicator;
ENUM_TIMEFRAMES Indperiod2;
input int indperiod2;
input int indparam2;
input int RSIpricetype;
input int RSIbuyCriterion;
input int RSIsellCriterion;

double SDArray[];
int SDIndicator;
ENUM_TIMEFRAMES Indperiod3;
input int indperiod3;
input int indparam3;
input int SDpricetype;
input int ma_mode = 0;
input double SDCriterion;

     
int OnInit()
  {
   Indperiod1 = Timeframe(indperiod1);
   ENUM_MA_METHOD Env_MA;
   switch(ma_mode)
     {
      case 1:
         Env_MA = MODE_SMA;
         break;

      case 2:
         Env_MA = MODE_EMA;
         break;

      case 3:
         Env_MA = MODE_SMMA;
         break;

      case 4:
         Env_MA = MODE_LWMA;
         break;
     }
   Indicator =  iEnvelopes(_Symbol,Indperiod1,span1,0,Env_MA,pricetype,deviation);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   
   Indperiod2 = Timeframe(indperiod2);
   ArraySetAsSeries(myRSIArray,true);
   RSIIndicator =iRSI(_Symbol,Indperiod2,indparam2,RSIpricetype);
   
   Indperiod3 = Timeframe(indperiod3);
   ArraySetAsSeries(SDArray,true);
   SDIndicator =iStdDev(_Symbol,Indperiod3,indparam3,0,Env_MA,SDpricetype);
   
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
   if(isNotEnoughMoney())
     {
      return;
     }
   if(isTooBigSpread(3))
     {
      return;
     }
   
   
 

   Bid=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
   Ask=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);

   CopyBuffer(Indicator, 0,0,2, high);
   CopyBuffer(Indicator, 1,0,2, low);

   if(high[0] == EMPTY_VALUE || low[0] == EMPTY_VALUE)
     {
      return;
     }
     
   
   CopyBuffer(RSIIndicator,0,0,1,myRSIArray);
   if(myRSIArray[0] ==EMPTY_VALUE){
      return;
   }
   
   CopyBuffer(SDIndicator,0,0,1,SDArray);
   if(SDArray[0] ==EMPTY_VALUE){
      return;
   }
   
   
   signal = "";
   if(myRSIArray[0] < RSIbuyCriterion )
     {
      signal="buy";

     }

   if(myRSIArray[0] > RSIsellCriterion )
     {
      signal="sell";
     }

   if(signal == "buy" && EachPositionsTotal("buy") < positions/2)
     {
      if((high[0]*TPbuy - Ask) > 25*_Point && (Ask - low[0]*SLbuy) > 9*_Point)
        {
         trade.Buy(lot,NULL,Ask,low[0]*SLbuy,high[0]*TPbuy,NULL);
        }
     }


   if(signal == "sell" && EachPositionsTotal("sell") < positions/2)
     {
      if((Bid - low[0]*TPsell) > 25*_Point  && (high[0]*SLsell- Bid) > 9*_Point)
        {
         trade.Sell(lot,NULL,Bid,high[0]*SLsell,low[0]*TPsell,NULL);
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

   if(long_trades > short_trades)
     {
      short_long_ratio = short_trades / long_trades;
     }
   else
     {
      short_long_ratio = long_trades / short_trades;
     }
   if(TesterStatistics(STAT_LONG_TRADES) > 0)
     {
      average_loss = TesterStatistics(STAT_GROSS_LOSS) / TesterStatistics(STAT_LOSS_TRADES);
     }
   if(profit_trades_number > 0)
     {
      average_profit = TesterStatistics(STAT_GROSS_PROFIT) / profit_trades_number;
     }
   if(TesterStatistics(STAT_LOSS_TRADES) > 0)
     {
      win_rate = profit_trades_number / TesterStatistics(STAT_LOSS_TRADES);
     }

   if(min_dd == 0 || average_profit == 0)
     {
      return -999999999;
     }


   param = MathSqrt(balance) * (1/min_dd)  * short_long_ratio *MathPow(trades_number,3);

   if(balance > 0)
     {


      if(average_profit > 10)
        {
         param = param/average_profit;
        }

      if(short_long_ratio < 0.4)
        {
         param = param/(1/short_long_ratio);
        }

      if(win_rate < 0.25)
        {
         param = param/(1/win_rate);
        }
     }

   if(balance < 0)
     {

      param = -MathSqrt(-balance) / ((1/min_dd)  * short_long_ratio *MathPow(trades_number,3));


      if(average_profit >10)
        {
         param = param*average_profit;
        }

      if(short_long_ratio < 0.4)
        {
         param = param*(1/short_long_ratio);
        }

      if(win_rate < 0.25)
        {
         param = param*(1/win_rate);
        }
     }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   return(param);
  }
//+------------------------------------------------------------------+
