//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

#include <Trade\OrderInfo.mqh>
#include <Original\MyUtils.mqh>
#include <Arrays\ArrayLong.mqh>

class MyOrder: public COrderInfo {
 public:
   CArrayLong SellTickets, BuyTickets;
   datetime Expiration;
   
   void MyOrder(datetime Expiration){
      this.Expiration = Expiration;
   }
   void Refresh() {
      SellTickets.Clear();
      BuyTickets.Clear();
      datetime current = TimeCurrent();
      for(int i = OrdersTotal() - 1; i >= 0; i--) {
         ulong ticket = OrderGetTicket(i);
         Select(ticket);
         if(Magic() != MagicNumber) break;
         ENUM_ORDER_TYPE orderType = OrderType();
         if(orderType == ORDER_TYPE_BUY_LIMIT || orderType == ORDER_TYPE_BUY_STOP) {
            BuyTickets.Add(ticket);
         } else {
            SellTickets.Add(ticket);
         }
         if(current - TimeSetup() > Expiration)
           cTrade.OrderDelete(ticket);
      }
   }
   
   void CloseAllOrders(){
      for(int i = 0; i < SellTickets.Total(); i++) {
        cTrade.OrderDelete(SellTickets.At(i));
      }
      for(int i = 0; i < BuyTickets.Total(); i++) {
        cTrade.OrderDelete(BuyTickets.At(i));
      }
   }
      
   int TotalEachOrders(ENUM_ORDER_TYPE OrderType) {
      return (OrderType == ORDER_TYPE_BUY) ? BuyTickets.Total() : SellTickets.Total();
   }
   
   void CheckExpiration(){
      for(int i=0;i<BuyTickets.Total();i++)
        {
         Select(BuyTickets.At(i));
        }
   }
   private:
     CTrade cTrade;
};
//+------------------------------------------------------------------+
