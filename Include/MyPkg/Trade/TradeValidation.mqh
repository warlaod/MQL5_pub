//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
#include <MyPkg\Trade\TradeRequest.mqh>

class TradeValidation: public CTrade {
 public:
   bool Check(tradeRequest &tR) {
      return 
         CheckStopLossAndTakeProfit(tR) &&
         CheckMoneyForTrade(tR) &&
         ModifyVolumeValue(tR.volume, tR.magicNumber);
         
   }
 private:

   bool CheckMoneyForTrade(tradeRequest &tR) {
      double requiredMargin = 0;
      double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
      //--- call of the checking function
      if(!OrderCalcMargin(tR.type, _Symbol, tR.volume, tR.openPrice, requiredMargin)) {
         //--- something went wrong, report and return false
         Print("Error in ", __FUNCTION__, " code=", GetLastError());
         return false;
      }
      //--- if there are insufficient funds to perform the operation
      if(requiredMargin > freeMargin) {
         //--- report the error and return false
         string accountCurrency = AccountInfoString(ACCOUNT_CURRENCY);
         Print("Not enough money for ", EnumToString(tR.type), " ", tR.volume, " ", _Symbol, ". At least ", requiredMargin, accountCurrency, " required");
         return false ;
      }
      //--- checking successful
      return(true);
   }
   
   // prevent invalid stoploss error;
   bool CheckStopLossAndTakeProfit(tradeRequest &tR) {
      //--- get the SYMBOL_TRADE_STOPS_LEVEL level
      int stopLevel = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
      int freezeLevel = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL);

      bool slCheck, tpCheck, check = false;

      switch(tR.type) {
      //--- Buy operation
      case ORDER_TYPE_BUY: {
         slCheck = (tR.openPrice - tR.sl > stopLevel * _Point);
         tpCheck = (tR.tp - tR.openPrice > stopLevel * _Point);
         return (slCheck && tpCheck);
      }
      //--- Sell operation
      case ORDER_TYPE_SELL: {
         slCheck = (tR.sl - tR.openPrice > stopLevel * _Point);
         tpCheck = (tR.openPrice - tR.tp > stopLevel * _Point);
         return (slCheck && tpCheck);
      }
      case  ORDER_TYPE_BUY_LIMIT: {
         //--- check the distance from the bidOrAsk to the open price
         check = ((tR.bidOrAsk - tR.openPrice) > freezeLevel * _Point);
         return check;
      }
      case  ORDER_TYPE_SELL_LIMIT: {
         check = ((tR.openPrice - tR.bidOrAsk) > freezeLevel * _Point);
         return check;
      }
      case  ORDER_TYPE_BUY_STOP: {
         check = ((tR.openPrice - tR.bidOrAsk) > freezeLevel * _Point);
         return check;
      }
      case  ORDER_TYPE_SELL_STOP: {
         check = ((tR.bidOrAsk - tR.openPrice) > freezeLevel * _Point);
         return check;
      }
      }
      return true;
   }

   bool ModifyVolumeValue(double &volume, ulong magicNumber) {
      //--- minimal allowed volume for trade operations
      double minVolume = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
      if(volume < minVolume) {
         printf("Volume is less than the minimal allowed SYMBOL_VOLUME_MIN=%.2f", minVolume);
         return(false);
      }

      //--- check maximal allowed volume of trade operations
      double maxVolume = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
      if(volume > maxVolume) {
         volume = maxVolume;
         printf("Volume is greater than the maximal allowed SYMBOL_VOLUME_MAX=%.2f, so use SYMBOL_VOLUME_MAX instead", maxVolume);
      }

      //--- check minimal step of volume changing
      double volumeStep = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
      volume = MathFloor(volume / volumeStep) * volumeStep;

      //--- check volume limit
      double symbolMaxVolume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_LIMIT);
      double currentUsedVolume = sumOrderVolume(magicNumber) + sumPositionVolume(magicNumber);
      if(symbolMaxVolume - currentUsedVolume < 0) {
         printf("Volume limit exceeded: allowed SYMBOL_VOLUME_LIMIT=%.2f", symbolMaxVolume);
      }

      //--- return that volume is valid
      return true;
   }

   double sumPositionVolume(ulong magicNumber) {
      double sum;
      double ta = PositionsTotal();
      for(int i = PositionsTotal() - 1; i >= 0; i--) {
         ulong ticket = PositionGetTicket(i);
         if(PositionGetInteger(POSITION_MAGIC) != magicNumber) continue;
         sum += PositionGetDouble(POSITION_VOLUME);
      }
      return sum;
   }

   double sumOrderVolume(ulong magicNumber) {
      double sum;
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
