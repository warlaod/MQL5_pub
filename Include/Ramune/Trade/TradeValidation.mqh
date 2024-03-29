//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
#include <Ramune\Trade\TradeRequest.mqh>
#include <Ramune\CommonFunc.mqh>
#include <Ramune\Logger.mqh>

class TradeValidation: public CTrade {
 public:
   bool Check(tradeRequest &tR, Logger &logger) {
      bool res2 = CheckStopLossAndTakeProfit(tR, logger);
      bool res3 = CheckMoneyForTrade(tR, logger);
      bool res4 =  ModifyVolumeValue(tR, logger);
      return res2 && res3 && res4;
   }

 private:
   bool CheckMoneyForTrade(tradeRequest &tR, Logger &logger) {
      double requiredMargin = 0;
      double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
      //--- call of the checking function
      if(!OrderCalcMargin(tR.type, tR.symbol, tR.volume, tR.openPrice, requiredMargin)) {
         //--- something went wrong, report and return false
         logger.Log(StringFormat("Error in ", __FUNCTION__, " code=", GetLastError()),Error);
         return false;
      }
      //--- if there are insufficient funds to perform the operation
      if(requiredMargin > freeMargin) {
         //--- report the error and return false
         string accountCurrency = AccountInfoString(ACCOUNT_CURRENCY);
         logger.Log(StringFormat("Not enough money for ", EnumToString(tR.type), " ", tR.volume, " ", tR.symbol, ". At least ", requiredMargin, accountCurrency, " required"),Warning);
         return false ;
      }
      //--- checking successful
      return(true);
   }

   // prevent invalid stoploss error;
   bool CheckStopLossAndTakeProfit(tradeRequest &tR, Logger &logger) {
      //--- get the SYMBOL_TRADE_STOPS_LEVEL level
      int stopLevel = (int)SymbolInfoInteger(tR.symbol, SYMBOL_TRADE_STOPS_LEVEL);
      int freezeLevel = (int)SymbolInfoInteger(tR.symbol, SYMBOL_TRADE_FREEZE_LEVEL);
      double point = SymbolInfoDouble(tR.symbol,SYMBOL_POINT);

      double ask = Ask(tR.symbol);
      double bid = Bid(tR.symbol);

      bool slCheck, tpCheck, check = false;

      switch(tR.type) {
      //--- Buy operation
      case  ORDER_TYPE_BUY: {
         //--- check the StopLoss
         slCheck = (bid - tR.sl > stopLevel * point);
         tpCheck = (tR.tp - bid > stopLevel * point);
         return(slCheck && tpCheck);
      }
      //--- Sell operation
      case  ORDER_TYPE_SELL: {
         //--- check the StopLoss
         slCheck = (tR.sl - ask > stopLevel * point);
         tpCheck = (ask - tR.tp > stopLevel * point);
         return(tpCheck && slCheck);
      }

      case  ORDER_TYPE_BUY_LIMIT: {
         //--- check the distance from the opening price to the activation price
         check = ((ask - tR.openPrice) > freezeLevel * point);
         return(check);
      }
      //--- BuyLimit pending order
      case  ORDER_TYPE_SELL_LIMIT: {
         //--- check the distance from the opening price to the activation price
         check = ((tR.openPrice - bid) > freezeLevel * point);
         return(check);
      }
      //--- BuyStop pending order
      case  ORDER_TYPE_BUY_STOP: {
         //--- check the distance from the opening price to the activation price
         check = ((tR.openPrice - ask) > freezeLevel * point);
         return(check);
      }
      //--- SellStop pending order
      case  ORDER_TYPE_SELL_STOP: {
         //--- check the distance from the opening price to the activation price
         check = ((bid - tR.openPrice) > freezeLevel * point);
         return(check);
      }
      break;
      }
      return true;
   }


   bool ModifyVolumeValue(tradeRequest &tR, Logger &logger) {
      //--- minimal allowed volume for trade operations
      double minVolume = SymbolInfoDouble(tR.symbol, SYMBOL_VOLUME_MIN);
      if(tR.volume < minVolume) {
         logger.Log(StringFormat("Trade cancelled: Volume(current: %.2f) is less than the minimal allowed SYMBOL_VOLUME_MIN=%.2f",tR.volume, minVolume),Warning);
         return(false);
      }

      //--- check maximal allowed volume of trade operations
      double maxVolume = SymbolInfoDouble(tR.symbol, SYMBOL_VOLUME_MAX);
      if(tR.volume > maxVolume) {
         tR.volume = maxVolume;
         logger.Log(StringFormat("Volume is greater than the maximal allowed SYMBOL_VOLUME_MAX=%.2f, so use SYMBOL_VOLUME_MAX instead", maxVolume),Info);
      }

      //--- check minimal step of volume changing
      double volumeStep = SymbolInfoDouble(tR.symbol, SYMBOL_VOLUME_STEP);
      tR.volume = MathFloor(tR.volume / volumeStep) * volumeStep;

      //--- check volume limit
      double symbolMaxVolume = SymbolInfoDouble(tR.symbol, SYMBOL_VOLUME_LIMIT);
      if(symbolMaxVolume == 0) {
         symbolMaxVolume = maxVolume;
      }
      double currentUsedVolume = sumOrderVolume(tR.magicNumber) + sumPositionVolume(tR.magicNumber);
      if(symbolMaxVolume - (currentUsedVolume + tR.volume) < 0) {
         logger.Log(StringFormat("Trade cancelled: Volume limit exceeded: allowed SYMBOL_VOLUME_LIMIT=%.2f, current=%.2f, ordered=%.2f", symbolMaxVolume,currentUsedVolume,tR.volume),Warning);
         return(false);
      }

      //--- return that volume is valid
      return true;
   }

   double sumPositionVolume(ulong magicNumber) {
      double sum = 0;
      double ta = PositionsTotal();
      for(int i = PositionsTotal() - 1; i >= 0; i--) {
         ulong ticket = PositionGetTicket(i);
         if(PositionGetInteger(POSITION_MAGIC) != magicNumber) continue;
         sum += PositionGetDouble(POSITION_VOLUME);
      }
      return sum;
   }

   double sumOrderVolume(ulong magicNumber) {
      double sum = 0;
      for(int i = OrdersTotal() - 1; i >= 0; i--) {
         ulong ticket = OrderGetTicket(i);
         if(OrderGetInteger(ORDER_MAGIC) != magicNumber) continue;
         sum += OrderGetDouble(ORDER_VOLUME_CURRENT);
      }
      return sum;
   }
};
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
