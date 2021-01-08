//+------------------------------------------------------------------+
//|                                                       MyTest.mqh |
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
class MyTest {
 private:
   double  result;
   double balance;
   double min_dd;
   double equity_dd;
   double balance_dd;
   double  total_trades;
   double  profit_trades;
   double loss_trades;
   double long_trades;
   double long_profit_trades;
   double short_trades;
   double short_profit_trades;
   double gross_profit;
   double gross_loss;
   double average_profit;
   double average_loss;
   double win_rate;
   double short_long_ratio;
   double  short_win_rate;
   double long_win_rate;
   double marginlevel_min;
   double positiveEffector;
   double negativeEffector;
   double conlossMax;
   double maxConloss;


 public:
   double min_dd_and_mathsqrt_profit_trades() {
      if(result == -99999999) {
         return result;
      }
      positiveEffector = min_dd * total_trades;
      negativeEffector = 1;

      CheckRatio(short_long_ratio, 0.1);
      CheckRatio(win_rate, 0.1);
      CheckRatio(short_win_rate, 0.1);
      CheckRatio(long_win_rate, 0.1);
      SetResultForBalance();

      return result;
   }

   double min_dd_and_mathsqrt_profit_trades_without_balance() {
      if(result == -99999999) {
         return result;
      }
      positiveEffector = min_dd * profit_trades;
      negativeEffector = 1;

      CheckRatio(short_long_ratio, 0.1);
      CheckRatio(win_rate, 0.1);
      CheckRatio(short_win_rate, 0.1);
      CheckRatio(long_win_rate, 0.1);
      SetResultWithOutBalance();

      return result;
   }

   double min_dd_and_profit_trades() {
      if(result == -99999999) {
         return result;
      }
      positiveEffector = min_dd * profit_trades;
      negativeEffector = 1;

      CheckRatio(short_long_ratio, 0.1);
      CheckRatio(win_rate, 0.1);
      CheckRatio(short_win_rate, 0.1);
      CheckRatio(long_win_rate, 0.1);
      SetResultForBalance();

      return result;
   }

   double min_dd_and_mathsqrt_profit_trades_only_longs() {

      if(long_profit_trades <= 10) {
         return -99999999;
      }
      if(balance_dd == 0 && equity_dd == 0) {
         return -99999999;
      }

      min_dd = 1 / equity_dd;

      long_win_rate = long_profit_trades / (total_trades - short_trades);
      positiveEffector = min_dd * long_profit_trades;

      if(positiveEffector == 0) return -99999999;

      negativeEffector = 1;

      CheckRatio(long_win_rate, 0.25);
      SetResultForBalance();

      return result;
   }

   double PROM() {
      if(result == -99999999) {
         return result;
      }
      int AAGP = (gross_profit * profit_trades) * sqrt(profit_trades);
      int AAGL = (gross_loss * loss_trades) * sqrt(loss_trades);
      positiveEffector = (AAGP - AAGL) / gross_loss / maxConloss;
      negativeEffector = 1;

      CheckRatio(short_long_ratio, 0.1);
      CheckRatio(win_rate, 0.1);
      CheckRatio(short_win_rate, 0.1);
      CheckRatio(long_win_rate, 0.1);
      SetResultWithOutBalance();

      return result;
   }

 private:
   void CheckRatio(double ratio, double criterion) {
      if(ratio > criterion) return;
      negativeEffector = negativeEffector / ratio;
   }

   void SetResultForBalance() {
      if(balance > 0) {
         result = balance * positiveEffector / negativeEffector ;
      } else {
         result = balance / positiveEffector * negativeEffector ;
      }
   }

   void SetResultWithOutBalance() {
      if(balance > 0) {
         result =  positiveEffector / negativeEffector ;
      } else {
         result = 1 / positiveEffector * negativeEffector ;
      }
   }

 public:
   void MyTest() {
      balance = TesterStatistics(STAT_PROFIT);
      total_trades = TesterStatistics(STAT_TRADES);
      profit_trades = TesterStatistics(STAT_PROFIT_TRADES);
      loss_trades = TesterStatistics(STAT_LOSS_TRADES);
      long_trades = TesterStatistics(STAT_LONG_TRADES);
      long_profit_trades = TesterStatistics(STAT_PROFIT_LONGTRADES);
      short_trades = TesterStatistics(STAT_SHORT_TRADES);
      short_profit_trades = TesterStatistics(STAT_PROFIT_SHORTTRADES);
      gross_profit = TesterStatistics(STAT_GROSS_PROFIT);
      gross_loss =  TesterStatistics(STAT_GROSS_LOSS);
      marginlevel_min  = TesterStatistics(STAT_MIN_MARGINLEVEL);
      balance_dd = TesterStatistics(STAT_BALANCE_DD);
      equity_dd = TesterStatistics(STAT_EQUITY_DD);
      conlossMax = TesterStatistics(STAT_CONLOSSMAX);
      maxConloss = TesterStatistics(STAT_MAX_CONLOSSES);
      average_profit = 0;
      average_loss = 0;
      win_rate = 0;
      short_long_ratio = 0;
      short_win_rate = 0;
      long_win_rate = 0;


      if(long_trades <= 10 || short_trades <= 10) {
         result = -99999999;
         return;
      }
      if(long_profit_trades <= 10 || short_profit_trades <= 10) {
         result = -99999999;
         return;
      }
      if(balance_dd == 0 && equity_dd == 0) {
         result = -99999999;
         return;
      }

      min_dd = 1 / equity_dd;


      if(marginlevel_min < 200) {
         result = -99999999;
         return;
      }

      short_long_ratio = short_trades / long_trades;
      if(short_long_ratio > 1) {
         short_long_ratio = 1 / short_long_ratio ;
      }

      win_rate = (loss_trades == 0) ? 1 : profit_trades / total_trades ;
      short_win_rate = short_profit_trades / (total_trades - long_trades);
      long_win_rate = long_profit_trades / (total_trades - short_trades);
      average_profit = gross_profit / profit_trades;
      if(loss_trades != 0) {
         average_loss = gross_loss / loss_trades;
      } else {
         average_loss = 1;
      }
   }
};
//+------------------------------------------------------------------+
