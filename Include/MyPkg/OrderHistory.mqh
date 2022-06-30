//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
 #include <Trade\HistoryOrderInfo.mqh>
class OrderHistory: public CHistoryOrderInfo {
   ulong magicNumber;
   void OrderHistory(ulong magicNumber){
      this.magicNumber = magicNumber;
   }
   void getLastDeal(){
      HistorySelect(0,TimeCurrent());
   ulong ticket_history_deal=0;
   int counter=0;
   string text="";
//--- for all deals
   for(uint i=HistoryDealsTotal()-1; i>=0; i--)
     {
      //--- try to get deals ticket_history_deal
      if((ticket_history_deal=HistoryDealGetTicket(i))>0)
        {
         long     deal_ticket       =HistoryDealGetInteger(ticket_history_deal,DEAL_TICKET);
         long     deal_time         =HistoryDealGetInteger(ticket_history_deal,DEAL_TIME);
         long     deal_type         =HistoryDealGetInteger(ticket_history_deal,DEAL_TYPE);
         long     deal_entry        =HistoryDealGetInteger(ticket_history_deal,DEAL_ENTRY);
         long     deal_magic        =HistoryDealGetInteger(ticket_history_deal,DEAL_MAGIC);
         double   deal_commission   =HistoryDealGetDouble(ticket_history_deal,DEAL_COMMISSION);
         double   deal_swap         =HistoryDealGetDouble(ticket_history_deal,DEAL_SWAP);
         double   deal_profit       =HistoryDealGetDouble(ticket_history_deal,DEAL_PROFIT);
         string   deal_symbol       =HistoryDealGetString(ticket_history_deal,DEAL_SYMBOL);
         //---
         if((InpSymbol==deal_symbol || InpSymbol=="") && (InpMagic==deal_magic || InpMagic<0))
           {
            if(deal_entry==DEAL_ENTRY_OUT)
              {
               counter++;
               string time=TimeToString((datetime)deal_time,TIME_DATE|TIME_MINUTES|TIME_SECONDS);
               text=text+"\n"+time+" | "+DoubleToString(deal_commission+deal_swap+deal_profit,2);
               if(counter==InpN)
                 {
                  m_from_date=(datetime)deal_time;
                  break;
                 }
              }
           }
        }
     }
   }
};
//+------------------------------------------------------------------+
