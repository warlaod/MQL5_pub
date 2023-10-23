//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#include <Expert\Trailing\TrailingFixedPips.mqh>
#include <Expert\Expert.mqh>
#include <Trade\PositionInfo.mqh>
#include <Ramune\CommonFunc.mqh>
#include <Ramune\Trailing\Base.mqh>
#include <Trade\Trade.mqh>

// The class just for storing postion tickes
class Pips: public Base {
 public:
   void TrailLong(string symbol, ulong ticket, int stopPips, int profitPips ) {
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

   void TrailShort(string symbol,ulong ticket, int stopPips, int profitPips ) {
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

   void TrailLongs(string symbol, CArrayLong &buyTickets, int stopPips, int profitPips = 50) {
      for(int i = buyTickets.Total() - 1; i >= 0; i--) {
         ulong ticket = buyTickets.At(i);
         this.TrailLong(symbol,ticket, stopPips, profitPips);
      }
   }

   void TrailShorts(string symbol, CArrayLong &sellTickets, int stopPips, int profitPips = 50 ) {
      for(int i = sellTickets.Total() - 1; i >= 0; i--) {
         ulong ticket = sellTickets.At(i);
         this.TrailShort(symbol, ticket, stopPips, profitPips);
      }
   }
};
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
