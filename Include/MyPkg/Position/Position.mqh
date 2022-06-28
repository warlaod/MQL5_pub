//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

#include <Trade\PositionInfo.mqh>
#include <MyPkg\CommonFunc.mqh>

class Position: public CPositionInfo {
   double pips;

 public:
   void Position() {
      this.pips = Pips();
   }
   
   double ProfitInPips(ulong ticket) {
      SelectByTicket(ticket);
      double profit = PriceCurrent() - PriceOpen();
      if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
         profit = - profit;
      }
      return profit / pips;
   }
};
//+------------------------------------------------------------------+
