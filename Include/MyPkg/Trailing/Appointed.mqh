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
class Appointed: public Base {
 public:
   void ModifyLongPosition(ulong ticket, double newStop, string symbol) {
      position.SelectByTicket(ticket);
      double sl = position.StopLoss();
      double base  = (sl == 0.0) ? position.PriceOpen() : sl;
      double price = Bid(symbol);

      int stopLevel = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
      double level = price - stopLevel * _Point;

      if(newStop > base && newStop < level) {
         trade.PositionModify(ticket, newStop, price + 300 * _Point * digitAdjust);
      }
   };

   void TrailLong(CArrayLong &buyTickets, double newStop, string symbol) {
      for(int i = buyTickets.Total() - 1; i >= 0; i--) {
         ulong ticket = buyTickets.At(i);
         this.ModifyLongPosition(ticket, newStop, symbol);
      }
   }

   void ModifyShortPosition(ulong ticket, double newStop, string symbol) {
      position.SelectByTicket(ticket);
      double sl = position.StopLoss();
      double base  = (sl == 0.0) ? position.PriceOpen() : sl;
      double price = Ask(symbol);

      int stopLevel = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
      double level = price + stopLevel * _Point;

      if(newStop < base && newStop > level) {
         trade.PositionModify(ticket, newStop, price - 300 * _Point * digitAdjust);
      }
   };

   void TrailShort(CArrayLong &sellTickets, double newStop, string symbol) {
      for(int i = sellTickets.Total() - 1; i >= 0; i--) {
         ulong ticket = sellTickets.At(i);
         this.ModifyShortPosition(ticket, newStop, symbol);
      }
   }
};
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
