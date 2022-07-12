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
   void Appointed(string symbol):Base(symbol) { }
   
   void TrailLong(string symbol, ulong ticket, double newSL, double newTP) {
      position.SelectByTicket(ticket);
      double sl = position.StopLoss();
      double base  = (sl == 0.0) ? position.PriceOpen() : sl;
      double price = Bid(symbol);

      int stopLevel = (int)SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);
      double point = SymbolInfoDouble(symbol,SYMBOL_POINT);
      double level = price - stopLevel * point;

      if(newSL > base && newSL < level) {
         trade.PositionModify(ticket, newSL, newTP);
      }
   };

   void TrailLongs(string symbol, CArrayLong &buyTickets, double newSL, double newTP) {
      for(int i = buyTickets.Total() - 1; i >= 0; i--) {
         ulong ticket = buyTickets.At(i);
         this.TrailLong(symbol, ticket, newSL, newTP);
      }
   }

   void TrailShort(string symbol, ulong ticket, double newSL, double newTP) {
      position.SelectByTicket(ticket);
      double sl = position.StopLoss();
      double base  = (sl == 0.0) ? position.PriceOpen() : sl;
      double price = Ask(symbol);

      int stopLevel = (int)SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);
      double point = SymbolInfoDouble(symbol,SYMBOL_POINT);
      double level = price + stopLevel * point;

      if(newSL < base && newSL > level) {
         trade.PositionModify(ticket, newSL, newTP);
      }
   };

   void TrailShorts(string symbol, CArrayLong &sellTickets, double newSL, double newTP) {
      for(int i = sellTickets.Total() - 1; i >= 0; i--) {
         ulong ticket = sellTickets.At(i);
         this.TrailShort(symbol, ticket, newSL, newTP);
      }
   }
};
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
