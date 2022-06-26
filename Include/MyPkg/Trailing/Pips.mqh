//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#include <Expert\Trailing\TrailingFixedPips.mqh>
#include <Expert\Expert.mqh>
#include <Trade\PositionInfo.mqh>
#include <MyPkg\CommonFunc.mqh>
#include <MyPkg\Trailing\Base.mqh>
#include <Trade\Trade.mqh>

// The class just for storing postion tickes
class Pips: public Base {
 public:
   void ModifyLongPosition(ulong ticket, int profitPips, int stopPips, string symbol) {
      position.SelectByTicket(ticket);
      double sl = position.StopLoss();
      double base  = (sl == 0.0) ? position.PriceOpen() : sl;
      double price = Bid(symbol);

      double delta = stopPips * pips;
      if(price - base <= delta) return;

      double fixedSl = price - delta;
      double fixedTp = price + profitPips * pips;

      trade.PositionModify(ticket, fixedSl, fixedTp);
   };

   void ModifyShortPosition(ulong ticket, double stopPips, double profitPips, string symbol) {
      position.SelectByTicket(ticket);
      double sl = position.StopLoss();
      double base  = (sl == 0.0) ? position.PriceOpen() : sl;
      double price = Ask(symbol);

      double delta = stopPips * pips;
      if(base - price <= delta) return;

      double fixedSl = price + delta;
      double fixedTp = price - profitPips * pips;

      trade.PositionModify(ticket, fixedSl, fixedTp);
   };

   void TrailLong(CArrayLong &buyTickets, int stopPips, int profitPips = 50) {
      for(int i = buyTickets.Total() - 1; i >= 0; i--) {
         ulong ticket = buyTickets.At(i);
         this.ModifyLongPosition(ticket, stopPips, profitPips);
      }
   }

   void TrailShort(CArrayLong &sellTickets, int stopPips, int profitPips = 50 ) {
      for(int i = sellTickets.Total() - 1; i >= 0; i--) {
         ulong ticket = sellTickets.At(i);
         this.ModifyShortPosition(ticket, stopPips, profitPips);
      }
   }
};
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
