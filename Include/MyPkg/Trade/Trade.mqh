//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
#include <MyPkg\Trade\TradeValidation.mqh>
#include <MyPkg\Trade\TradeRequest.mqh>
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

   void OpenPosition(tradeRequest &tR) {
      if(!validation.Check(tR)) return;
      CTrade::PositionOpen(tR.symbol, tR.type, tR.volume, tR.openPrice, tR.sl, tR.tp);
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
