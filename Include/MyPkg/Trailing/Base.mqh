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
class Base {
 public:
   CPositionInfo position;
   CTrade trade;
   double pips;

   void Base() {
      this.pips = Pips();
   }

   virtual void TrailLong(CArrayLong &buyTickets, int profitPips, int stopPips) {
   }

   virtual void TrailShort(CArrayLong &sellTickets, int profitPips, int stopPips) {
   }

   virtual void ModifyLongPosition(ulong ticket, int profitPips, int stopPips) {
   };

   virtual void ModifyShortPosition(ulong ticket, double stopPips, double profitPips) {
   };
};
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
