//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
#include <Ramune\Trade\TradeValidation.mqh>
#include <Ramune\Trade\TradeRequest.mqh>
#include <Arrays\ArrayLong.mqh>

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class Trade: public CTrade {
 public:
   TradeValidation validation;

   void Trade(ulong magicNumber) {
      this.SetExpertMagicNumber(magicNumber);
      SetDeviationInPoints(10);
   };

   void OpenPosition(tradeRequest &tR, Logger &logger) {
      if(!validation.Check(tR, logger)) return;
      CTrade::PositionOpen(tR.symbol, tR.type, tR.volume, tR.openPrice, tR.sl, tR.tp);

      int retcode = ResultRetcode();
      if(retcode != TRADE_RETCODE_DONE)
         logger.Log(StringFormat("trade was requested{Type:%s, Volume:%g, Price:%g, S/L:%g, T/P:%g}, but got retcode = %i", EnumToString(tR.type), tR.volume, tR.openPrice, tR.sl, tR.tp, retcode), Info);
   }

   void ClosePositions(CArrayLong &tickets) {
      for(int i = tickets.Total() - 1; i >= 0; i--) {
         PositionClose(tickets.At(i));
      }
   }
};
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
