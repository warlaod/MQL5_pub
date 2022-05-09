//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
#include <MyPkg\Trade\TradeValidation.mqh>
#include <MyPkg\Trade\TradeRequest.mqh>
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

   void PositionOpen(tradeRequest &tR) {
      if(!validation.Check(tR)) return;
      CTrade::PositionOpen(_Symbol, tR.type, tR.volume, tR.openPrice, tR.sl, tR.tp);
   }
};
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
