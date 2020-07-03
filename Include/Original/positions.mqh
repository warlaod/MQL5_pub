//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2018, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
#include <Original\period.mqh>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int EachPositionsTotal(string type)
  {
   int buyPosiCount = 0;
   int sellPosiCount = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      string symbol = PositionGetSymbol(i);
      if(_Symbol == symbol)
        {
         if(PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_SELL)
           {
            sellPosiCount++;
           }
         if(PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_BUY)
           {
            buyPosiCount++;
           }
        }
     }

   if(type == "buy")
     {
      return buyPosiCount;
     }
   if(type == "sell")
     {
      return sellPosiCount;
     }
   return 0;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseAllBuyPositions()
  {
   CTrade itrade;
   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      ulong ticket = PositionGetTicket(i);

      if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
        {
         itrade.PositionClose(ticket);
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseAllSellPositions()
  {
   CTrade itrade;
   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      ulong ticket = PositionGetTicket(i);

      if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
        {
         itrade.PositionClose(ticket);
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TrailingStop(double Ask, double Bid, int SL, int TP, bool isLong,bool isShort)
  {
   CTrade itrade;
   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      string symbol = PositionGetSymbol(i);
      if(_Symbol == symbol)
        {
         ulong PositionTicket=PositionGetInteger(POSITION_TICKET);
         double CurrentTP =PositionGetDouble(POSITION_TP);
         double CurrentSL =PositionGetDouble(POSITION_SL);
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY && isLong)
           {
            if(Ask -CurrentSL > SL*_Point)
              {
               itrade.PositionModify(PositionTicket,(Ask-SL*_Point),CurrentTP+TP);
              }
           }
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL && isShort)
           {
            if(CurrentSL - Bid > SL*_Point)
              {
               itrade.PositionModify(PositionTicket,(Bid+SL*_Point),CurrentTP+TP);
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SetSL(double Ask, double Bid, double SL, bool isLong,bool isShort)
  {
   CTrade itrade;
   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      string symbol = PositionGetSymbol(i);
      if(_Symbol == symbol)
        {
         ulong PositionTicket=PositionGetInteger(POSITION_TICKET);
         double CurrentTP =PositionGetDouble(POSITION_TP);
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY && isLong)
           {
            if(Ask - SL > 100*_Point)
              {
               itrade.PositionModify(PositionTicket,SL,CurrentTP);
              }
           }
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL && isShort)
           {
            if(SL - Bid> 100*_Point)
              {
               itrade.PositionModify(PositionTicket,SL,CurrentTP);
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int StopLossCount(int Trades,int Min)
  {
   HistorySelect(TimeCurrent()-60*Min,TimeCurrent());
   int TotalDeals = HistoryDealsTotal();
   ulong TicketNumber;
   uint SLcount=0;
   int DealEntry;
   double StopLoss;

   for(int i=TotalDeals-Trades*2; i<TotalDeals; i++)
     {
      if(i < 0)
        {
         i=0;
        }
      TicketNumber = HistoryDealGetTicket(i);
      if(TicketNumber >0)
        {
         StopLoss =HistoryDealGetDouble(TicketNumber,DEAL_PROFIT);
         DealEntry = HistoryDealGetInteger(TicketNumber,DEAL_ENTRY);
         if(DealEntry == 1)
           {
            if(StopLoss < 0)
              {
               SLcount++;
              }
           }
        }
     }
   return SLcount;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool PreviousCloseHour(int &close_times[][2],bool which_summer, int hour, int min)
  {
   if(which_summer)
     {
      hour = (hour+1)%24;
     }
   int al = ArraySize(close_times);
   for(int i = 0; i < ArraySize(close_times)/2; i++)
     {
      int target_time =  close_times[i][0]*60 + close_times[i][1];
      int current_time = hour*60 + min;
      if(target_time == 0)
        {
         if(current_time > 23*60+57 || current_time < 3)
           {
            CloseAllBuyPositions();
            CloseAllSellPositions();
            return true;
           }
        }
      else
         if(MathAbs(target_time - current_time) < 3)
           {
            CloseAllBuyPositions();
            CloseAllSellPositions();
            return true;
           }
     }
   return false;
  }
//+------------------------------------------------------------------+
bool isNotInvalidTrade(double SL,double TP,double price,bool Long)
  {
   if(Long)
     {
      if(TP - price > 10*_Point && price - SL > 10*_Point)
        {
         return true;
        }
     }
   else
      if(price - TP > 10*_Point  && SL - price > 10*_Point)
        {
         return true;
        }

   return false;
  }
//+------------------------------------------------------------------+
