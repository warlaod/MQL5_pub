//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

#include <Trade\PositionInfo.mqh>
#include <MyPkg\CommonFunc.mqh>
#include <Arrays\ArrayLong.mqh>

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
   
   bool IsAnyPositionInRange(CArrayLong &tickets,double askOrBid, double range) {
      for(int i = 0; i < tickets.Total(); i++) {
         SelectByTicket(tickets.At(i));
         if(MathAbs(PriceOpen() - askOrBid) < range) {
            return true;
         }
      }
      return false;
   }
   
};
//+------------------------------------------------------------------+
