//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
#include <MyPkg\Trade\TradeRequest.mqh>
#include <MyPkg\CommonFunc.mqh>

class TradeValidation: public CTrade {
 public:
   bool Check(tradeRequest &tR) {
      bool res1 = CheckDoNotOrderInTheSameBar(tR);
      bool res2 = CheckStopLossAndTakeProfit(tR);
      bool res3 = CheckMoneyForTrade(tR);
      bool res4 =  ModifyVolumeValue(tR);
      return res1 && res2 && res3 && res4;
   }

 private:
   bool CheckDoNotOrderInTheSameBar(tradeRequest &tR) {
      HistorySelect(iTime(tR.symbol, tR.timeFrame, 0), TimeCurrent()); // Select history from bar open till now
      
      // if entry is detected within current bar, do not trande
      for(int i = 0; i < HistoryOrdersTotal(); i++) {
         ulong ticket = HistoryDealGetTicket(i);
         if(HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_IN) { 
            return false;
         }
      }
      return true;
   }

   bool CheckMoneyForTrade(tradeRequest &tR) {
      double requiredMargin = 0;
      double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
      //--- call of the checking function
      if(!OrderCalcMargin(tR.type, tR.symbol, tR.volume, tR.openPrice, requiredMargin)) {
         //--- something went wrong, report and return false
         Print("Error in ", __FUNCTION__, " code=", GetLastError());
         return false;
      }
      //--- if there are insufficient funds to perform the operation
      if(requiredMargin > freeMargin) {
         //--- report the error and return false
         string accountCurrency = AccountInfoString(ACCOUNT_CURRENCY);
         Print("Not enough money for ", EnumToString(tR.type), " ", tR.volume, " ", tR.symbol, ". At least ", requiredMargin, accountCurrency, " required");
         return false ;
      }
      //--- checking successful
      return(true);
   }

   // prevent invalid stoploss error;
   bool CheckStopLossAndTakeProfit(tradeRequest &tR) {
      //--- get the SYMBOL_TRADE_STOPS_LEVEL level
      int stopLevel = (int)SymbolInfoInteger(tR.symbol, SYMBOL_TRADE_STOPS_LEVEL);
      int freezeLevel = (int)SymbolInfoInteger(tR.symbol, SYMBOL_TRADE_FREEZE_LEVEL);

      double ask = Ask(tR.symbol);
      double bid = Bid(tR.symbol);

      bool slCheck, tpCheck, check = false;

      switch(tR.type) {
      //--- Buy operation
      case  ORDER_TYPE_BUY: {
         //--- check the StopLoss
         slCheck = (bid - tR.sl > stopLevel * _Point);
         tpCheck = (tR.tp - bid > stopLevel * _Point);
         return(slCheck && tpCheck);
      }
      //--- Sell operation
      case  ORDER_TYPE_SELL: {
         //--- check the StopLoss
         slCheck = (tR.sl - ask > stopLevel * _Point);
         tpCheck = (ask - tR.tp > stopLevel * _Point);
         return(tpCheck && slCheck);
      }

      case  ORDER_TYPE_BUY_LIMIT: {
         //--- check the distance from the opening price to the activation price
         check = ((ask - tR.openPrice) > freezeLevel * _Point);
         return(check);
      }
      //--- BuyLimit pending order
      case  ORDER_TYPE_SELL_LIMIT: {
         //--- check the distance from the opening price to the activation price
         check = ((tR.openPrice - bid) > freezeLevel * _Point);
         return(check);
      }
      //--- BuyStop pending order
      case  ORDER_TYPE_BUY_STOP: {
         //--- check the distance from the opening price to the activation price
         check = ((tR.openPrice - ask) > freezeLevel * _Point);
         return(check);
      }
      //--- SellStop pending order
      case  ORDER_TYPE_SELL_STOP: {
         //--- check the distance from the opening price to the activation price
         check = ((bid - tR.openPrice) > freezeLevel * _Point);
         return(check);
      }
      break;
      }
      return true;
   }


   bool ModifyVolumeValue(tradeRequest &tR) {
      double volume = tR.volume;
      
      //--- minimal allowed volume for trade operations
      double minVolume = SymbolInfoDouble(tR.symbol, SYMBOL_VOLUME_MIN);
      if(volume < minVolume) {
         printf("Volume is less than the minimal allowed SYMBOL_VOLUME_MIN=%.2f", minVolume);
         return(false);
      }

      //--- check maximal allowed volume of trade operations
      double maxVolume = SymbolInfoDouble(tR.symbol, SYMBOL_VOLUME_MAX);
      if(volume > maxVolume) {
         volume = maxVolume;
         printf("Volume is greater than the maximal allowed SYMBOL_VOLUME_MAX=%.2f, so use SYMBOL_VOLUME_MAX instead", maxVolume);
      }

      //--- check minimal step of volume changing
      double volumeStep = SymbolInfoDouble(tR.symbol, SYMBOL_VOLUME_STEP);
      volume = MathFloor(volume / volumeStep) * volumeStep;

      //--- check volume limit
      double symbolMaxVolume = SymbolInfoDouble(tR.symbol, SYMBOL_VOLUME_LIMIT);
      if(symbolMaxVolume == 0) {
         symbolMaxVolume = maxVolume;
      }
      double currentUsedVolume = sumOrderVolume(tR.magicNumber) + sumPositionVolume(tR.magicNumber);
      if(symbolMaxVolume - currentUsedVolume < 0) {
         printf("Volume limit exceeded: allowed SYMBOL_VOLUME_LIMIT=%.2f", symbolMaxVolume);
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
