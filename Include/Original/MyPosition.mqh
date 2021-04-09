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
#include <Original\MySymbolAccount.mqh>
#include <Arrays\ArrayLong.mqh>
#include <Generic\HashMap.mqh>

input double positionCloseMinPow = -1;
input int positions = 1;

class MyPosition: public CPositionInfo {

 public:
   int Total;
   int CloseMin;
   CHashMap<ulong, bool > TrailingTickets, PartialClosedTickets;
   CArrayLong SellTickets, BuyTickets;
   int LotDigit;
   MySymbolAccount SA;

   void MyPosition() {
      CloseMin = 10 * MathPow(2, positionCloseMinPow);
      MyTrade myTrade;
      LotDigit = SA.LotDigits;
   }

   void Refresh() {
      Total = PositionsTotal();
      BuyTickets.Clear();
      SellTickets.Clear();
      for(int i = Total - 1; i >= 0; i--) {
         ulong ticket = PositionGetTicket(i);
         if(Magic() != MagicNumber) continue;
         SelectByTicket(ticket);
         if(PositionType() == POSITION_TYPE_BUY) {
            BuyTickets.Add(ticket);
         } else {
            SellTickets.Add(ticket);
         }
      }
   }

   bool isPositionInRange( ENUM_POSITION_TYPE PositionType, double Range) {
      CArrayLong Tickets;
      double EntryPrice;
      if(PositionType == POSITION_TYPE_BUY) {
         Tickets = BuyTickets;
         EntryPrice = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
      } else {
         Tickets = SellTickets;
         EntryPrice = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
      }
      for(int i = 0; i < Tickets.Total(); i++) {
         SelectByTicket(Tickets.At(i));
         if(MathAbs(PriceOpen() - EntryPrice) < Range) {
            return true;
         }
      }
      return false;
   }

   bool isAnyPositionHasProfit(ENUM_POSITION_TYPE PositionType, double Profit = 0) {
      CArrayLong Tickets = (PositionType == POSITION_TYPE_BUY) ? BuyTickets : SellTickets;
      for(int i = 0; i < Tickets.Total(); i++) {
         SelectByTicket(Tickets.At(i));
         if(CurrentProfit() > Profit) return true;
      }
      return false;
   }

   void CloseAllPositions(ENUM_POSITION_TYPE PositionType) {
      CArrayLong Tickets = (PositionType == POSITION_TYPE_BUY) ? BuyTickets : SellTickets;
      for(int i = 0; i < Tickets.Total(); i++) {
         itrade.PositionClose(Tickets.At(i));
      }
   }

   void CloseAllPositions() {
      for(int i = 0; i < BuyTickets.Total(); i++) {
         itrade.PositionClose(BuyTickets.At(i));
      }
      for(int i = 0; i < SellTickets.Total(); i++) {
         itrade.PositionClose(SellTickets.At(i));
      }
   }

   void CloseAllPositionsInMinute() {
      if(positionCloseMinPow == -1) return;
      for(int i = 0; i < BuyTickets.Total(); i++) {
         int ticket = BuyTickets.At(i);
         SelectByTicket(ticket);
         if( TimeCurrent() - Time() >= CloseMin * 60 )
            itrade.PositionClose(ticket);
      }
      for(int i = 0; i < SellTickets.Total(); i++) {
         int ticket = SellTickets.At(i);
         SelectByTicket(ticket);
         if( TimeCurrent() - Time() >= CloseMin * 60 )
            itrade.PositionClose(ticket);
      }
   }

   void CloseAllPositionsByProfit(ENUM_POSITION_TYPE PType, double TP = NULL, double SL = NULL) {
      CTrade itrade;
      for(int i = Total - 1; i >= 0; i--) {
         SelectByTicket(PositionGetTicket(i));
         if(Magic() != MagicNumber) continue;
         if(PositionType() != PType) continue;
         double profit = Profit() * _Point;
         if(profit > TP && TP != 0 )
            itrade.PositionClose(PositionGetTicket(i));
         else if(profit < SL && SL != 0 )
            itrade.PositionClose(PositionGetTicket(i));
      }
   }

   void CloseEachPosition(ulong PositionTicket) {
      SelectByTicket(PositionTicket);
      if(Magic() != MagicNumber) return;
      itrade.PositionClose(PositionTicket);
   }

   void CloseEachPosition(ulong ticket, double lotPer) {
      SelectByTicket(ticket);
      itrade.PositionClosePartial(ticket, Volume()*lotPer);
   }

   void ClosePartial(ulong ticket, double perVolume) {
      if(PartialClosedTickets.ContainsKey(ticket))
         return;
      if(itrade.PositionClosePartial(ticket, NormalizeDouble(Volume()*perVolume, LotDigit)))
         PartialClosedTickets.Add(ticket, true);
   }

   int TotalEachPositions(ENUM_POSITION_TYPE PositionType) {
      return (PositionType == POSITION_TYPE_BUY) ? BuyTickets.Total() : SellTickets.Total();
   }

   void AddAllForTrailings() {
      for(int i = 0; i < BuyTickets.Total(); i++) {
         AddListForTrailings(BuyTickets.At(i));
      }
      for(int i = 0; i < SellTickets.Total(); i++) {
         AddListForTrailings(SellTickets.At(i));
      }
   }

   void CheckTargetPriceProfitableForTrailings(ENUM_POSITION_TYPE PositionType, double TargetPrice, double TP_Price = 0) {
      CArrayLong Tickets = (PositionType == POSITION_TYPE_BUY) ? BuyTickets : SellTickets;
      for(int i = 0; i < Tickets.Total(); i++) {
         ulong ticket = Tickets.At(i);
         SelectByTicket(ticket);
         if(TargetPriceProfit(TargetPrice) > TP_Price)
            AddListForTrailings(ticket);
      }
   }

   bool AddListForTrailings(ulong ticket) {
      if(TrailingTickets.ContainsKey(ticket)) return false;
      TrailingTickets.Add(ticket, true);
      return true;
   }

   void AddListForPartialClose(ulong ticket) {
      if(!PartialClosedTickets.ContainsKey(ticket))
         PartialClosedTickets.Add(ticket, true);
   }

   double MathStopLoss() {
      return MathAbs(StopLoss() - PriceOpen());
   }

   double TargetPriceProfit(double TargetPrice) {
      double profit = TargetPrice - PriceOpen();
      if(PositionType() == POSITION_TYPE_SELL) return -profit;
      return profit;
   }

   double CurrentProfit() {
      double profit = PriceCurrent() - PriceOpen();
      if(PositionType() == POSITION_TYPE_BUY)
         return profit;
      return -profit;
   }

   void Trailings(ENUM_POSITION_TYPE PositionType, double SL) {
      CArrayLong Tickets;
      myTrade.Refresh();
      double TP;
      if(PositionType == POSITION_TYPE_BUY) {
         Tickets = BuyTickets;
         TP = 100000;
      } else {
         Tickets = SellTickets;
         TP = 0;
      }
      for(int i = 0; i < Tickets.Total(); i++) {
         ulong ticket = Tickets.At(i);
         if(!TrailingTickets.ContainsKey(ticket)) continue;
         SelectByTicket(ticket);
         if(MathAbs(StopLoss() - PriceCurrent()) <= MathAbs(SL - PriceCurrent())) continue;
         if(myTrade.isInvalidTrade(SL, TP)) continue;
         itrade.PositionModify(ticket, SL, TP );
      }
   }

   long CloseByPassedBars(ENUM_POSITION_TYPE PType, ENUM_TIMEFRAMES priceTimeframe, int barsCount) {
      for(int i = Total - 1; i >= 0; i--) {
         SelectByTicket(PositionGetTicket(i));
         if(PositionType() != PType) continue;
         if(Magic() != MagicNumber) continue;
         if(Bars(_Symbol, priceTimeframe, Time(), TimeCurrent()) > barsCount) {
            double dwad = Ticket();
            CloseEachPosition(Ticket());
         }
      }
      return 0;
   }

 private:
   CTrade itrade;
   MyTrade myTrade;
};
//+------------------------------------------------------------------+
