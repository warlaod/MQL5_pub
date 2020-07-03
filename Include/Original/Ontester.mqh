//+------------------------------------------------------------------+
//|                                                     Ontester.mqh |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
// #define MacrosHello   "Hello, world!"
// #define MacrosYear    2010
//+------------------------------------------------------------------+
//| DLL imports                                                      |
//+------------------------------------------------------------------+
// #import "user32.dll"
//   int      SendMessageA(int hWnd,int Msg,int wParam,int lParam);
// #import "my_expert.dll"
//   int      ExpertRecalculate(int wParam,int lParam);
// #import
//+------------------------------------------------------------------+
//| EX5 imports                                                      |
//+------------------------------------------------------------------+
// #import "stdlib.ex5"
//   string ErrorDescription(int error_code);
// #import
//+------------------------------------------------------------------+
double  result = 0.0;
double balance = 0;
double min_dd = 0;
double  total_trades =0;
double  profit_trades = 0;
double loss_trades = 0;
double long_trades = 0;
double long_profit_trades = 0;
double short_trades = 0;
double short_profit_trades = 0;
double gross_profit = 0;
double gross_loss =  0;
double average_profit = 0;
double average_loss = 0;
double win_rate = 0;
double short_long_ratio = 0;
double  short_win_rate =0;
double long_win_rate =0;


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double testingScalpMoreTrade()
  {
   double positiveEffector = min_dd * MathPow(profit_trades,3);
   double negativeEffector = 1;

   if(average_profit > 9)
     {
      negativeEffector = negativeEffector * average_profit;
     }
   if(short_long_ratio < 0.70)
     {
      negativeEffector = negativeEffector * 1/short_long_ratio;
     }
   if(win_rate <0.25)
     {
      negativeEffector = negativeEffector *1/win_rate ;
     }
   if(short_win_rate < 0.25)
     {
      negativeEffector = negativeEffector * 1/short_win_rate;
     }
   if(long_win_rate < 0.25)
     {
      negativeEffector = negativeEffector * 1/long_win_rate;
     }

   balance = TesterStatistics(STAT_PROFIT);
   if(balance > 0)
     {
      result = MathSqrt(balance) * positiveEffector / negativeEffector ;
     }
   else
     {
      result = -MathSqrt(-balance) / positiveEffector * negativeEffector ;
     }

   return result;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double testingScalpMoreTradeLongs()
  {
   double positiveEffector = min_dd * MathPow(profit_trades,3);
   double negativeEffector = 1;

   if(average_profit > 9)
     {
      negativeEffector = negativeEffector * average_profit;
     }
   if(win_rate <0.25)
     {
      negativeEffector = negativeEffector *1/win_rate ;
     }

   balance = TesterStatistics(STAT_PROFIT);
   if(balance > 0)
     {
      result = MathSqrt(balance) * positiveEffector / negativeEffector ;
     }
   else
     {
      result = -MathSqrt(-balance) / positiveEffector * negativeEffector ;
     }

   return result;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double testingScalpMoreTradeShort()
  {
   double positiveEffector = min_dd * MathPow(profit_trades,3);
   double negativeEffector = 1;

   if(average_profit > 9)
     {
      negativeEffector = negativeEffector * average_profit;
     }

   if(win_rate <0.25)
     {
      negativeEffector = negativeEffector *1/win_rate ;
     }

   balance = TesterStatistics(STAT_PROFIT);
   if(balance > 0)
     {
      result = MathSqrt(balance) * positiveEffector / negativeEffector ;
     }
   else
     {
      result = -MathSqrt(-balance) / positiveEffector * negativeEffector ;
     }

   return result;
  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double testingScalpLessProfit()
  {
   double positiveEffector = min_dd * profit_trades;
   double negativeEffector = 1;

   if(average_profit > 9)
     {
      negativeEffector = negativeEffector * average_profit;
     }
   if(short_long_ratio < 0.70)
     {
      negativeEffector = negativeEffector * 1/short_long_ratio;
     }
   if(win_rate <0.25)
     {
      negativeEffector = negativeEffector *1/win_rate ;
     }
   if(short_win_rate < 0.25)
     {
      negativeEffector = negativeEffector * 1/short_win_rate;
     }
   if(long_win_rate < 0.25)
     {
      negativeEffector = negativeEffector * 1/long_win_rate;
     }

   balance = TesterStatistics(STAT_PROFIT);
   if(balance > 0)
     {
      result = MathSqrt(balance) * positiveEffector / negativeEffector ;
     }
   else
     {
      result = -MathSqrt(-balance) / positiveEffector * negativeEffector ;
     }

   return result;
  }

double testingScalp()
  {
   double positiveEffector = min_dd * profit_trades;
   double negativeEffector = 1;

   if(average_profit > 9)
     {
      negativeEffector = negativeEffector * average_profit;
     }
   if(short_long_ratio < 0.70)
     {
      negativeEffector = negativeEffector * 1/short_long_ratio;
     }
   if(win_rate <0.25)
     {
      negativeEffector = negativeEffector *1/win_rate ;
     }
   if(short_win_rate < 0.25)
     {
      negativeEffector = negativeEffector * 1/short_win_rate;
     }
   if(long_win_rate < 0.25)
     {
      negativeEffector = negativeEffector * 1/long_win_rate;
     }

   balance = TesterStatistics(STAT_PROFIT);
   if(balance > 0)
     {
      result = balance * positiveEffector / negativeEffector ;
     }
   else
     {
      result = balance / positiveEffector * negativeEffector ;
     }

   return result;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double testingNormal()
  {
   double positiveEffector = min_dd * MathSqrt(profit_trades);
   double negativeEffector = 1;


   if(short_long_ratio < 0.70)
     {
      negativeEffector = negativeEffector * 1/short_long_ratio;
     }
   if(win_rate <0.25)
     {
      negativeEffector = negativeEffector *1/win_rate ;
     }
   if(short_win_rate < 0.25)
     {
      negativeEffector = negativeEffector * 1/short_win_rate;
     }
   if(long_win_rate < 0.25)
     {
      negativeEffector = negativeEffector * 1/long_win_rate;
     }

   balance = TesterStatistics(STAT_PROFIT);
   if(balance > 0)
     {
      result = balance * positiveEffector / negativeEffector ;
     }
   else
     {
      result = balance / positiveEffector * negativeEffector ;
     }

   return result;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double balance_and_min_dd()
  {
   double positiveEffector = min_dd;
   double negativeEffector = 1;


   if(short_long_ratio < 0.70)
     {
      negativeEffector = negativeEffector * 1/short_long_ratio;
     }
   if(win_rate <0.25)
     {
      negativeEffector = negativeEffector *1/win_rate ;
     }
   if(short_win_rate < 0.25)
     {
      negativeEffector = negativeEffector * 1/short_win_rate;
     }
   if(long_win_rate < 0.25)
     {
      negativeEffector = negativeEffector * 1/long_win_rate;
     }

   balance = TesterStatistics(STAT_PROFIT);
   if(balance > 0)
     {
      result = balance * positiveEffector / negativeEffector ;
     }
   else
     {
      result = balance / positiveEffector * negativeEffector ;
     }

   return result;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool setVariables()
  {
   total_trades = TesterStatistics(STAT_TRADES);
   profit_trades = TesterStatistics(STAT_PROFIT_TRADES);
   loss_trades = TesterStatistics(STAT_LOSS_TRADES);
   long_trades = TesterStatistics(STAT_LONG_TRADES);
   long_profit_trades = TesterStatistics(STAT_PROFIT_LONGTRADES);
   short_trades = TesterStatistics(STAT_SHORT_TRADES);
   short_profit_trades = TesterStatistics(STAT_PROFIT_SHORTTRADES);
   gross_profit = TesterStatistics(STAT_GROSS_PROFIT);
   gross_loss =  TesterStatistics(STAT_GROSS_LOSS);
   average_profit = 0;
   average_loss = 0;
   win_rate = 0;
   short_long_ratio = 0;
   short_win_rate =0;
   long_win_rate =0;

   if(long_trades == 0 || short_trades == 0 || loss_trades == 0)
     {
      return false;
     }
   if(long_profit_trades == 0 || short_profit_trades == 0)
     {
      return false;
     }
   if(TesterStatistics(STAT_EQUITY_DDREL_PERCENT) == 0)
     {
      return false;
     }
   min_dd = 1/(TesterStatistics(STAT_BALANCE_DD));
   short_long_ratio = short_trades / long_trades;
   if(short_long_ratio > 1)
     {
      short_long_ratio = 1/short_long_ratio ;
     }

   win_rate = profit_trades / total_trades ;
   short_win_rate = short_profit_trades/(total_trades - long_trades);
   long_win_rate =long_profit_trades/(total_trades - short_trades);
   average_profit = gross_profit / profit_trades;
   average_loss = gross_loss / loss_trades;

   return true;
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool setVariableLongs()
  {
   total_trades = TesterStatistics(STAT_TRADES);
   profit_trades = TesterStatistics(STAT_PROFIT_TRADES);
   loss_trades = TesterStatistics(STAT_LOSS_TRADES);
   long_trades = TesterStatistics(STAT_LONG_TRADES);
   long_profit_trades = TesterStatistics(STAT_PROFIT_LONGTRADES);
   short_trades = TesterStatistics(STAT_SHORT_TRADES);
   short_profit_trades = TesterStatistics(STAT_PROFIT_SHORTTRADES);
   gross_profit = TesterStatistics(STAT_GROSS_PROFIT);
   gross_loss =  TesterStatistics(STAT_GROSS_LOSS);
   average_profit = 0;
   average_loss = 0;
   win_rate = 0;
   short_long_ratio = 0;
   short_win_rate =0;
   long_win_rate =0;

   if(long_trades == 0 || loss_trades == 0)
     {
      return false;
     }
   if(long_profit_trades == 0)
     {
      return false;
     }
   if(TesterStatistics(STAT_EQUITY_DDREL_PERCENT) == 0)
     {
      return false;
     }
  min_dd = 1/(TesterStatistics(STAT_BALANCE_DD));


   win_rate = profit_trades / total_trades ;
   average_profit = gross_profit / profit_trades;
   average_loss = gross_loss / loss_trades;

   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool setVariableShorts()
  {
   total_trades = TesterStatistics(STAT_TRADES);
   profit_trades = TesterStatistics(STAT_PROFIT_TRADES);
   loss_trades = TesterStatistics(STAT_LOSS_TRADES);
   long_trades = TesterStatistics(STAT_LONG_TRADES);
   long_profit_trades = TesterStatistics(STAT_PROFIT_LONGTRADES);
   short_trades = TesterStatistics(STAT_SHORT_TRADES);
   short_profit_trades = TesterStatistics(STAT_PROFIT_SHORTTRADES);
   gross_profit = TesterStatistics(STAT_GROSS_PROFIT);
   gross_loss =  TesterStatistics(STAT_GROSS_LOSS);
   average_profit = 0;
   average_loss = 0;
   win_rate = 0;
   short_long_ratio = 0;
   short_win_rate =0;
   long_win_rate =0;

   if(short_trades == 0 || loss_trades == 0)
     {
      return false;
     }
   if(short_profit_trades == 0)
     {
      return false;
     }
   if(TesterStatistics(STAT_EQUITY_DDREL_PERCENT) == 0)
     {
      return false;
     }
  min_dd = 1/(TesterStatistics(STAT_BALANCE_DD));



   win_rate = profit_trades / total_trades ;
   average_profit = gross_profit / profit_trades;
   average_loss = gross_loss / loss_trades;

   return true;
  }
//+------------------------------------------------------------------+
