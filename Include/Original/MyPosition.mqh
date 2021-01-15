//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Original\MyPrice.mqh>
#include <Original\MyUtils.mqh>
#include <Original\MyTrade.mqh>
#include <Arrays\ArrayLong.mqh>
#include <Generic\HashMap.mqh>

input double positionCloseMinPow = -1;

class MyPosition {
 public:
   MqlDateTime dt;
   int Total;
   int CloseMin;
   CHashMap<ulong, bool > TrailingTickets, PartialCloseTickets;
   CArrayLong SellTickets, BuyTickets;


   void MyPosition() {
      CloseMin = 10 * MathPow(2, positionCloseMinPow);
   }

   void Refresh() {
      Total = PositionsTotal();
      BuyTickets.Clear();
      SellTickets.Clear();
      for(int i = Total - 1; i >= 0; i--) {
         ulong ticket = PositionGetTicket(i);
         cPositionInfo.SelectByTicket(ticket);
         if(cPositionInfo.PositionType() == POSITION_TYPE_BUY) {
            BuyTickets.Add(ticket);
         } else {
            SellTickets.Add(ticket);
         }
      }
   }

   bool isPositionInRange(double Range, ENUM_POSITION_TYPE PositionType) {
      CArrayLong Tickets = (PositionType == POSITION_TYPE_BUY) ? BuyTickets : SellTickets;
      for(int i = 0; i < Tickets.Total(); i++) {
         cPositionInfo.SelectByTicket(Tickets.At(i));
         if(MathAbs(cPositionInfo.Profit()) < Range) {
            return true;
         }
      }
      return false;
   }

   bool isPositionInTPRange(double Range, double CurrentPrice, ENUM_POSITION_TYPE PositionType) {
      for(int i = Total - 1; i >= 0; i--) {
         cPositionInfo.SelectByTicket(PositionGetTicket(i));
         if(cPositionInfo.PositionType() != PositionType) continue;
         if(cPositionInfo.Magic() != MagicNumber) continue;
         if(PositionType == POSITION_TYPE_BUY) {
            if(cPositionInfo.PriceOpen() - CurrentPrice < Range) return true;
         }
         if(PositionType == POSITION_TYPE_SELL) {
            if(CurrentPrice - cPositionInfo.PriceOpen() < Range) return true;
         }
      }
      return false;
   }

   void CloseAllPositions(ENUM_POSITION_TYPE PositionType) {
      CArrayLong Tickets = (PositionType == POSITION_TYPE_BUY) ? BuyTickets : SellTickets;
      for(int i = 0; i < Tickets.Total(); i++) {
         int ticket = Tickets.At(i);
         cPositionInfo.SelectByTicket(ticket);
         itrade.PositionClose(ticket);
      }
   }

   void CloseAllPositionsInMinute() {
      if(positionCloseMinPow == -1) return;
      for(int i = 0; i < BuyTickets.Total(); i++) {
         int ticket = BuyTickets.At(i);
         if( TimeCurrent() - cPositionInfo.Time() >= CloseMin * 60 )
            itrade.PositionClose(ticket);
      }
      for(int i = 0; i < SellTickets.Total(); i++) {
         int ticket = SellTickets.At(i);
         if( TimeCurrent() - cPositionInfo.Time() >= CloseMin * 60 )
            itrade.PositionClose(ticket);
      }
   }

   void CloseAllPositionsByProfit(ENUM_POSITION_TYPE PositionType, double TP = NULL, double SL = NULL) {
      CTrade itrade;
      for(int i = Total - 1; i >= 0; i--) {
         cPositionInfo.SelectByTicket(PositionGetTicket(i));
         if(cPositionInfo.Magic() != MagicNumber) continue;
         if(cPositionInfo.PositionType() != PositionType) continue;
         double profit = cPositionInfo.Profit() * _Point;
         if(profit > TP && TP != 0 )
            itrade.PositionClose(PositionGetTicket(i));
         else if(profit < SL && SL != 0 )
            itrade.PositionClose(PositionGetTicket(i));
      }
   }

   void CloseEachPosition(ulong PositionTicket) {
      CTrade itrade;
      cPositionInfo.SelectByTicket(PositionTicket);
      if(cPositionInfo.Magic() != MagicNumber) return;
      itrade.PositionClose(PositionTicket);
   }

   void CloseEachPosition(ulong ticket, double lotPer) {
      cPositionInfo.SelectByTicket(ticket);
      itrade.PositionClosePartial(ticket, cPositionInfo.Volume()*lotPer);
   }

   void ClosePartial(ulong ticket, double perVolume) {
      if(!TrailingTickets.ContainsKey(ticket)) return;
      cPositionInfo.SelectByTicket(ticket);
      itrade.PositionClosePartial(ticket, cPositionInfo.Volume()*perVolume);
   }

   int TotalEachPositions(ENUM_POSITION_TYPE PositionType) {
      CArrayLong Tickets = (PositionType == POSITION_TYPE_BUY) ? BuyTickets : SellTickets;
      return Tickets.Total();
   }

   void AddListForTrailings(ulong ticket) {
      cPositionInfo.SelectByTicket(ticket);
      if(!TrailingTickets.ContainsKey(ticket))
         TrailingTickets.Add(ticket, true);
   }

   void AddListForPartialClose(ulong ticket) {
      cPositionInfo.SelectByTicket(ticket);
      if(!PartialCloseTickets.ContainsKey(ticket))
         PartialCloseTickets.Add(ticket, true);
   }

   void Trailings(ENUM_POSITION_TYPE PositionType, double SL, double TP) {
      CArrayLong Tickets = (PositionType == POSITION_TYPE_BUY) ? BuyTickets : SellTickets;
      for(int i = 0; i < Tickets.Total(); i++) {
         ulong ticket = Tickets.At(i);
         if(!TrailingTickets.ContainsKey(ticket)) continue;
         cPositionInfo.SelectByTicket(ticket);
         if(MathAbs(cPositionInfo.StopLoss() - cPositionInfo.PriceCurrent()) < MathAbs(SL - cPositionInfo.PriceCurrent())) continue;
         itrade.PositionModify(ticket, SL, TP );
      }

   }

   void SetSL(ENUM_POSITION_TYPE PositionType, double SL) {
      MyTrade myTrade;
      myTrade.Refresh();
      for(int i = Total - 1; i >= 0; i--) {
         cPositionInfo.SelectByTicket(PositionGetTicket(i));
         if(cPositionInfo.PositionType() != PositionType) continue;
         if(cPositionInfo.Magic() != MagicNumber) continue;
         if(MathAbs(cPositionInfo.StopLoss() - cPositionInfo.PriceCurrent()) < MathAbs(SL - cPositionInfo.PriceCurrent())) continue;
         if(PositionType == POSITION_TYPE_BUY) {
            myTrade.PositionModify(cPositionInfo.Identifier(), SL, cPositionInfo.TakeProfit() );
         } else if(PositionType == POSITION_TYPE_SELL) {
            myTrade.PositionModify(cPositionInfo.Identifier(), SL, cPositionInfo.TakeProfit() );
         }
      }
   }

   long CloseByPassedBars(ENUM_POSITION_TYPE PositionType, ENUM_TIMEFRAMES priceTimeframe, int barsCount) {
      for(int i = Total - 1; i >= 0; i--) {
         cPositionInfo.SelectByTicket(PositionGetTicket(i));
         if(cPositionInfo.PositionType() != PositionType) continue;
         if(cPositionInfo.Magic() != MagicNumber) continue;
         if(Bars(_Symbol, priceTimeframe, cPositionInfo.Time(), TimeCurrent()) > barsCount) {
            double dwad = cPositionInfo.Ticket();
            CloseEachPosition(cPositionInfo.Ticket());
         }
      }
      return 0;
   }



 private:
   CPositionInfo cPositionInfo;
   CTrade itrade;
};
//+------------------------------------------------------------------+
