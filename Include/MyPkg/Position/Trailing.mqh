//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#include <Expert\Trailing\TrailingFixedPips.mqh>
#include <Expert\Expert.mqh>
#include <Trade\PositionInfo.mqh>
#include <MyPkg\CommonFunc.mqh>
#include <Trade\Trade.mqh>
// The class just for storing postion tickes
class Trailing {
 public:
   CPositionInfo position;
   CTrade trade;
   double digitAdjust;

   void Trailing() {
      this.digitAdjust = DigitAdjust();
   }

   void TrailLongPosition(CArrayLong &buyTickets, int profitPips, int stopPips) {
      for(int i = buyTickets.Total() - 1; i >= 0; i--) {
         ulong ticket = buyTickets.At(i);
         ModifyLongPosition(ticket, stopPips, profitPips);
      }
   }

   void ModifyLongPosition(ulong ticket, double stopPips, double profitPips) {
      position.SelectByTicket(ticket);
      double sl = position.StopLoss();
      double base  = (sl == 0.0) ? position.PriceOpen() : sl;
      double price = Bid();

      double delta = stopPips * _Point * digitAdjust;
      if(price - base <= delta) return;

      double fixedSl = price - delta;
      double fixedTp = price + profitPips * _Point * digitAdjust;

      trade.PositionModify(ticket, fixedSl, fixedTp);
   };
   
   void TrailShortPosition(CArrayLong &sellTickets, int profitPips, int stopPips) {
      for(int i = sellTickets.Total() - 1; i >= 0; i--) {
         ulong ticket = sellTickets.At(i);
         ModifyShortPosition(ticket, stopPips, profitPips);
      }
   }

   void ModifyShortPosition(ulong ticket, double stopPips, double profitPips) {
      position.SelectByTicket(ticket);
      double sl = position.StopLoss();
      double base  = (sl == 0.0) ? position.PriceOpen() : sl;
      double price = Ask();

      double delta = stopPips * _Point * digitAdjust;
      if(base-price <= delta) return;

      double fixedSl =price+delta;
      double fixedTp = price - profitPips * _Point * digitAdjust;

      trade.PositionModify(ticket, fixedSl, fixedTp);
   };
};
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
