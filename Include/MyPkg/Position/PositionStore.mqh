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
   CArrayLong sellTickets, buyTickets;
   ulong magicNumber;

   void PositionStore(ulong magicNumber) {
      this.magicNumber = magicNumber;
   };
   
   void Refresh(){
      buyTickets.Clear();
      sellTickets.Clear();
      for(int i = PositionsTotal() - 1; i >= 0; i--) {
         ulong ticket = PositionGetTicket(i);
         if(PositionGetInteger(POSITION_MAGIC) != magicNumber) continue;
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
            buyTickets.Add(ticket);
         } else {
            sellTickets.Add(ticket);
         };
      };
   }
};
//+------------------------------------------------------------------+
