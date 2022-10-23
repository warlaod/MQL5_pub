//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#include <MyPkg\Trade\TradeRequest.mqh>
#include <Expert\Money\MoneyFixedMargin.mqh>
#include <MyPkg\CommonFunc.mqh>

class VolumeByMargin: public CMoneyFixedMargin {
 public:
   CSymbolInfo    m_symbol;
   void VolumeByMargin(double riskPercent, string symbol) {
      m_symbol.Name(symbol);
      m_symbol.Refresh();
//---
      Init(GetPointer(m_symbol), Period(), m_symbol.Point()* DigitAdjust(symbol));
      Percent(riskPercent); // 1% risk
      ValidationSettings();
   }

   bool CalcurateVolume(tradeRequest &tR, Logger &logger) {
      tR.volume = this.MaxLotCheck(tR.symbol,tR.type,tR.openPrice,m_percent, logger);
      if(tR.volume == 0)
         return false;
//--- return trading volume
      return true;
   }

   double MaxLotCheck(const string symbol, const ENUM_ORDER_TYPE trade_operation,
                      const double price, const double percent, Logger &logger) const {
      double margin = 0.0;
//--- checks
      if(symbol == "" || price <= 0.0 || percent > 100) {
         logger.Log("CAccountInfo::MaxLotCheck invalid parameters",Error);
         return(0.0);
      }
      long leverage = AccountInfoInteger(ACCOUNT_LEVERAGE);
//--- calculate margin requirements for 1 lot
      if(!OrderCalcMargin(trade_operation, symbol, 1.0, price, margin) || margin < 0.0) {
         logger.Log("CAccountInfo::MaxLotCheck margin calculation failed",Error);
         return(0.0);
      }
//---
      if(margin == 0.0) // for pending orders
         return(SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX));
//--- calculate maximum volume
      double volume = NormalizeDouble(m_account.FreeMargin() * percent / 100.0 / margin, 2);
//--- normalize and check limits
      double stepvol = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
      if(stepvol > 0.0)
         volume = stepvol * MathFloor(volume / stepvol);
         
//--- return volume
      return(volume);
   }
};
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
