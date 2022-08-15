//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#include <Generic\HashMap.mqh>

class Optimization {
 public:
   double deposit;
   double profit;
   double trades;
   double profitTrades;
   double lossTrades;
   double longTrades;
   double shortTrades;
   double profitLongTrades;
   double profitShortTrades;
   double grossProfit;
   double grossLoss;
   double minMarginLevel;
   double balanceDd;
   double balanceDdrelPercent;
   double equityDd;
   double equityDdrelPercent;
   double conProfitMax;
   double conLossMax;


   void Optimization() {
      deposit = TesterStatistics(STAT_INITIAL_DEPOSIT);
      profit = TesterStatistics(STAT_PROFIT);
      trades =  TesterStatistics(STAT_TRADES);
      profitTrades =  TesterStatistics(STAT_PROFIT_TRADES);
      lossTrades = TesterStatistics(STAT_LOSS_TRADES);
      longTrades = TesterStatistics(STAT_LONG_TRADES);
      profitLongTrades =  TesterStatistics(STAT_PROFIT_LONGTRADES);
      shortTrades =  TesterStatistics(STAT_SHORT_TRADES);
      profitShortTrades = TesterStatistics(STAT_PROFIT_SHORTTRADES);
      grossProfit = TesterStatistics(STAT_GROSS_PROFIT);
      grossLoss =  TesterStatistics(STAT_GROSS_LOSS);
      minMarginLevel =  TesterStatistics(STAT_MIN_MARGINLEVEL);
      balanceDd = TesterStatistics(STAT_BALANCE_DD);
      balanceDdrelPercent = TesterStatistics(STAT_BALANCE_DDREL_PERCENT);
      equityDd = TesterStatistics(STAT_EQUITY_DD);
      equityDdrelPercent = TesterStatistics(STAT_EQUITY_DDREL_PERCENT);
      conProfitMax = TesterStatistics(STAT_MAX_CONWINS);
      conLossMax = TesterStatistics(STAT_CONLOSSMAX);
   }

   bool CheckResultValid() {
      if(trades == 0) return false;
      return true;
   }
   
   double PROM() {
      if(!CheckResultValid()) return NULL;
      
      double AAGP = (grossProfit / profitTrades) * (profitTrades - sqrt(profitTrades));
      double AAGL = (grossLoss / lossTrades) * (lossTrades + sqrt(lossTrades));
      double result = (AAGP - AAGL) / deposit;
      return result;
   }
   
   double PROMNegative() {
      if(!CheckResultValid()) return 0;
      
      double AAGP = (grossProfit / profitTrades) * (profitTrades - sqrt(profitTrades));
      double AAGL = (grossLoss / lossTrades) * (lossTrades + sqrt(lossTrades)) + conLossMax;
      double result = (AAGP - AAGL) / deposit;
      return result;
   }
   
   double Custom() {
      if(!CheckResultValid()) return 0;
      
      double profitFactor = 1 / equityDdrelPercent  * minMarginLevel * sqrt(trades);
      double base = profit;
      double result =  base * profitFactor;
      if(profit < 0){
       result = base / profitFactor;
      }
      
      
      return result;
   }
   
   double ViceVersa() {
      if(!CheckResultValid()) return 0;
      
      double profitFactor = 1 / equityDdrelPercent;
      double base = profit;
      double result =  base * profitFactor;
      if(profit < 0){
       result = base / profitFactor;
      }
      
      return result;
   }
   
   double Custom2() {
      if(!CheckResultValid()) return -99999;
      
      double result =  profit / (equityDdrelPercent * 100) * MathSqrt(trades);
      return result;
   }
};
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
