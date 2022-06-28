//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#include <Trade\PositionInfo.mqh>
#include <Arrays\ArrayLong.mqh>

// The class just for storing postion tickes
class PositionStoreForTrailing {

 public:
   CArrayLong sellTickets, buyTickets;
   
   void AddBuyTicket(ulong ticket){
      if(buyTickets.SearchLinear(ticket) != -1) return;
      buyTickets.Add(ticket);
   }
   
   void AddSellTicket(ulong ticket){
      if(sellTickets.SearchLinear(ticket) != -1) return;
      sellTickets.Add(ticket);
   }
   void Refresh(CArrayLong &sellPositionTickets, CArrayLong &buyPositionTickets){
      for(int i = sellTickets.Total() - 1; i >= 0; i--) {
         ulong ticket = sellTickets.At(i);
         if(sellPositionTickets.SearchLinear(ticket) == -1){
            sellTickets.Delete(i);
         }
      };
      
      for(int i = buyTickets.Total() - 1; i >= 0; i--) {
         ulong ticket = buyTickets.At(i);
         if(buyPositionTickets.SearchLinear(ticket) == -1){
            buyTickets.Delete(i);
         }
      };
   }
};
//+------------------------------------------------------------------+
