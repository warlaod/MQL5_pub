//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#include <MyPkg\Trade\TradeRequest.mqh>
#include <Expert\Money\MoneyFixedRisk.mqh>
#include <MyPkg\CommonFunc.mqh>

class Volume: public CMoneyFixedRisk {
 public:
   CSymbolInfo    m_symbol;
   void Volume(double riskPercent,string symbol) {
      m_symbol.Name(symbol);
      m_symbol.Refresh();
//---
      Init(GetPointer(m_symbol), Period(), m_symbol.Point()* DigitAdjust());
      Percent(riskPercent); // 1% risk
      ValidationSettings();
   }

   bool CalcurateVolume(tradeRequest &tR) {
      ENUM_ORDER_TYPE type = ORDER_TYPE_SELL;
      if(tR.type == ORDER_TYPE_BUY || tR.type == ORDER_TYPE_BUY_LIMIT || tR.type == ORDER_TYPE_BUY_STOP) {
         type = ORDER_TYPE_BUY;
      }

      double loss = -m_account.OrderProfitCheck(m_symbol.Name(), type, 1.0, tR.openPrice, tR.sl);
      if(loss == 0){
         return false;
      }
      double stepvol = m_symbol.LotsStep();
      tR.volume = MathFloor(m_account.Balance() * m_percent / loss / 100.0 / stepvol) * stepvol;
      if(tR.volume == 0){
         return false;
      }

      double maxvol = m_symbol.LotsMax();
      if(tR.volume > maxvol)
         tR.volume = maxvol;
//--- return trading volume
      return true;
   }
   
   bool CalcurateVolumeByRisk(tradeRequest &tR, int risk){
      double stepvol = m_symbol.LotsStep();
      tR.volume = MathFloor(m_account.Balance() / risk / stepvol) * stepvol;
      if(tR.volume == 0){
         return false;
      }

      double maxvol = m_symbol.LotsMax();
      if(tR.volume > maxvol)
         tR.volume = maxvol;
//--- return trading volume
      return true;
   }
};
//+------------------------------------------------------------------+
