//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class TradeValidation: public CTrade {
 public:
   // prevent invalid stoploss error;
   bool CheckPosition_StopLoss_TakeProfit(ENUM_ORDER_TYPE type, double openPrice, double sl, double tp) {
//--- get the SYMBOL_TRADE_STOPS_LEVEL level
      int stopLevel = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
      bool slCheck = false, tpCheck = false;
      switch(type) {
      //--- Buy operation
      case ORDER_TYPE_BUY: {
         slCheck = (openPrice - sl > stopLevel * _Point);
         tpCheck = (tp - openPrice > stopLevel * _Point);
         break;
      }
      //--- Sell operation
      case ORDER_TYPE_SELL: {
         slCheck = (sl - openPrice > stopLevel * _Point);
         tpCheck = (openPrice - tp > stopLevel * _Point);
         break;
      }
      }
      return(slCheck && tpCheck);
   }
   
   // prevent invalid stoploss error;
   bool CheckOrder_StopLoss_TakeProfit(ENUM_ORDER_TYPE type, double bidOrAsk, double openPrice, double sl, double tp) {
      int freezeLevel = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL);
      bool check = false;
      switch(type) {
      case  ORDER_TYPE_BUY_LIMIT: {
         //--- check the distance from the bidOrAsk to the open price
         check = ((bidOrAsk - openPrice) > freezeLevel * _Point);
         break;
      }
      case  ORDER_TYPE_SELL_LIMIT: {
         check = ((openPrice - bidOrAsk) > freezeLevel * _Point);
         break;
      }
      case  ORDER_TYPE_BUY_STOP: {
         check = ((openPrice - bidOrAsk) > freezeLevel * _Point);
         break;
      }
      case  ORDER_TYPE_SELL_STOP: {
         check = ((bidOrAsk - openPrice) > freezeLevel * _Point);
         break;
      }
      }
      return check;
   };
};
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
