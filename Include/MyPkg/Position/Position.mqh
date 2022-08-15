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
   void Position(string symbol) {
      this.pips = Pips(symbol);
   }

   double Profit(ulong ticket) {
      SelectByTicket(ticket);
      double profit = PriceCurrent() - PriceOpen();
      if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
         profit = - profit;
      }
      return profit / pips;
   }
   
   double ProfitOnNextStopLoss(ulong ticket,double stopLoss) {
      SelectByTicket(ticket);
      double profit = stopLoss - PriceOpen();
      if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
         profit = - profit;
      }
      return profit;
   }

   bool IsAnyPositionInRange(string symbol, CArrayLong &tickets, double range) {
      for(int i = 0; i < tickets.Total(); i++) {
         SelectByTicket(tickets.At(i));
         if(this.Symbol() != symbol) continue;
         double pOpen = PriceOpen();
         double pCurrent = PriceCurrent();
         if(MathAbs(PriceOpen() - PriceCurrent()) < range) {
            return true;
         }
      }
      return false;
   }

};
//+------------------------------------------------------------------+
