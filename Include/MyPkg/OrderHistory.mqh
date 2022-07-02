//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#include <Trade\HistoryOrderInfo.mqh>
class OrderHistory: public CHistoryOrderInfo {
   ulong magicNumber;

 public:
   void OrderHistory(ulong magicNumber) {
      this.magicNumber = magicNumber;
   }

   bool wasOrderInTheSameBar(string symbol, ENUM_TIMEFRAMES tf) {
      HistorySelect(iTime(symbol, tf, 0), TimeCurrent());
      for(int i = HistoryDealsTotal() - 1; i >= 0; i--) {
         ulong ticket = HistoryDealGetTicket(i);
         int dealEntry = HistoryDealGetInteger(ticket, DEAL_ENTRY);
         int dealMagic        = HistoryDealGetInteger(ticket, DEAL_MAGIC);
         if(magicNumber != dealMagic) {
            continue;
         }
         if(dealEntry == DEAL_ENTRY_IN) {
            return true;
         }
      }
      return false;
   }
};
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
