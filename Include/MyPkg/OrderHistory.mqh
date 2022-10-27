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
         if(symbol != HistoryDealGetString(ticket,DEAL_SYMBOL)) {
            continue;
         }
         if(dealEntry == DEAL_ENTRY_IN) {
            return true;
         }
      }
      return false;
   }

   double consecutiveLossCount(string symbol, ENUM_TIMEFRAMES tf, ENUM_DEAL_TYPE dType) {
      HistorySelect(0, TimeCurrent());
      int coef = 1;
      for(int i = HistoryDealsTotal() - 1; i >= 0; i--) {
         ulong ticket = HistoryDealGetTicket(i);
         int dealEntry = HistoryDealGetInteger(ticket, DEAL_ENTRY);
         int dealMagic        = HistoryDealGetInteger(ticket, DEAL_MAGIC);
         int dealType        = HistoryDealGetInteger(ticket, DEAL_TYPE);
         int dealReason = HistoryDealGetInteger(ticket, DEAL_REASON);
         double dealProfit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
         double dealVolume = HistoryDealGetDouble(ticket, DEAL_VOLUME);

         if(magicNumber != dealMagic) {
            continue;
         }

         if(dealEntry == DEAL_ENTRY_OUT) {
            if(dealType != dType || dealProfit > 0)
               break;
            if(dealReason == DEAL_REASON_SL) {
               return dealVolume;
            }

         }
      }
      return 0;
   }
};
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
