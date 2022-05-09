//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#include <Trade\PositionInfo.mqh>
#include <Arrays\ArrayLong.mqh>

// The class just for storing postion tickes
class PositionStore {

 public:
   CArrayLong sellTickes, buyTickes;

   void PositionStore(ulong magicNumber) {
      buyTickes.Clear();
      sellTickes.Clear();
      for(int i = PositionsTotal() - 1; i >= 0; i--) {
         ulong ticket = PositionGetTicket(i);
         if(PositionGetInteger(POSITION_MAGIC) != magicNumber) continue;
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
            buyTickes.Add(ticket);
         } else {
            sellTickes.Add(ticket);
         };
      };
   };
};
//+------------------------------------------------------------------+
