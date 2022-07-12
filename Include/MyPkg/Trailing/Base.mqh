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

   void Base(string symbol) {
      this.pips = Pips(symbol);
   }

   virtual void TrailLongs() {
   }

   virtual void TrailShorts() {
   }

   virtual void TrailLong() {
   };

   virtual void TrailShort() {
   };
};
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
