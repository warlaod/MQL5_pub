//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Original\MyPrice.mqh>
#include <Original\MyUtils.mqh>
#include <Original\MyTrade.mqh>

input int positionCloseMin;

class MyPosition {
 public:
  MqlDateTime dt;
  int Total;

  void Refresh() {
    Total = PositionsTotal();
  }

  bool isPositionInRange(double Range, ENUM_POSITION_TYPE PositionType) {
    for(int i = Total - 1; i >= 0; i--) {
      cPositionInfo.SelectByTicket(PositionGetTicket(i));
      if(cPositionInfo.PositionType() != PositionType) continue;
      if(cPositionInfo.Magic() != MagicNumber) continue;
      if(MathAbs(cPositionInfo.PriceOpen() - cPositionInfo.PriceCurrent()) < Range) {
        return true;
      }
    }
    return false;
  }

  bool isPositionInTPRange(double Range, double CurrentPrice, ENUM_POSITION_TYPE PositionType) {
    for(int i = Total - 1; i >= 0; i--) {
      cPositionInfo.SelectByTicket(PositionGetTicket(i));
      if(cPositionInfo.PositionType() != PositionType) continue;
      if(cPositionInfo.Magic() != MagicNumber) continue;
      if(PositionType == POSITION_TYPE_BUY) {
        if(cPositionInfo.PriceOpen() - CurrentPrice < Range) return true;
      }
      if(PositionType == POSITION_TYPE_SELL) {
        if(CurrentPrice - cPositionInfo.PriceOpen() < Range) return true;
      }
    }
    return false;
  }

  void CloseAllPositions(ENUM_POSITION_TYPE PositionType) {
    CTrade itrade;
    for(int i = Total - 1; i >= 0; i--) {
      cPositionInfo.SelectByTicket(PositionGetTicket(i));
      if(cPositionInfo.Magic() != MagicNumber) continue;
      if(cPositionInfo.PositionType() != PositionType) continue;
      itrade.PositionClose(PositionGetTicket(i));
    }
  }

  void CloseAllPositionsInMinute(int Minute) {
    if(Minute == 0) return;
    CTrade itrade;
    for(int i = Total - 1; i >= 0; i--) {
      cPositionInfo.SelectByTicket(PositionGetTicket(i));
      if(cPositionInfo.Magic() != MagicNumber) continue;
      int current = TimeCurrent();
      int order = cPositionInfo.Time();
      if( TimeCurrent() - cPositionInfo.Time() >= Minute * 60 )
        itrade.PositionClose(PositionGetTicket(i));
    }
  }

  void CloseAllPositionsByProfit(ENUM_POSITION_TYPE PositionType, double TP=NULL, double SL=NULL) {
    CTrade itrade;
    for(int i = Total - 1; i >= 0; i--) {
      cPositionInfo.SelectByTicket(PositionGetTicket(i));
      if(cPositionInfo.Magic() != MagicNumber) continue;
      if(cPositionInfo.PositionType() != PositionType) continue;
      double profit = cPositionInfo.Profit()*_Point;
      if(profit > TP && TP !=0 )
        itrade.PositionClose(PositionGetTicket(i));
      else if(profit < SL && SL !=0 )
        itrade.PositionClose(PositionGetTicket(i));
    }
  }

  void CloseEachPosition(ulong PositionTicket) {
    CTrade itrade;
    cPositionInfo.SelectByTicket(PositionTicket);
    if(cPositionInfo.Magic() != MagicNumber) return;
    itrade.PositionClose(PositionTicket);
  }

  int TotalEachPositions(ENUM_POSITION_TYPE PositionType) {
    CTrade itrade;
    int count = 0;
    for(int i = Total - 1; i >= 0; i--) {
      cPositionInfo.SelectByTicket(PositionGetTicket(i));
      if(cPositionInfo.Magic() != MagicNumber) continue;
      if(cPositionInfo.PositionType() != PositionType) continue;
      count++;
    }
    return count;
  }

  void Trailings(ENUM_POSITION_TYPE PositionType, double SL, double TP) {
    CTrade itrade;
    for(int i = Total - 1; i >= 0; i--) {
      cPositionInfo.SelectByTicket(PositionGetTicket(i));
      if(cPositionInfo.PositionType() != PositionType) continue;
      if(cPositionInfo.Magic() != MagicNumber) continue;
      if(MathAbs(cPositionInfo.StopLoss() - cPositionInfo.PriceCurrent()) < MathAbs(SL - cPositionInfo.PriceCurrent())) continue;
      if(PositionType == POSITION_TYPE_BUY) {
        itrade.PositionModify(cPositionInfo.Identifier(), SL, TP );
      } else if(PositionType == POSITION_TYPE_SELL) {
        itrade.PositionModify(cPositionInfo.Identifier(), SL, TP );
      }
    }
  }

  void SetSL(ENUM_POSITION_TYPE PositionType, double SL) {
    MyTrade myTrade;
    myTrade.Refresh();
    for(int i = Total - 1; i >= 0; i--) {
      cPositionInfo.SelectByTicket(PositionGetTicket(i));
      if(cPositionInfo.PositionType() != PositionType) continue;
      if(cPositionInfo.Magic() != MagicNumber) continue;
      if(MathAbs(cPositionInfo.StopLoss() - cPositionInfo.PriceCurrent()) < MathAbs(SL - cPositionInfo.PriceCurrent())) continue;
      if(PositionType == POSITION_TYPE_BUY) {
        myTrade.PositionModify(cPositionInfo.Identifier(), SL, cPositionInfo.TakeProfit() );
      } else if(PositionType == POSITION_TYPE_SELL) {
        myTrade.PositionModify(cPositionInfo.Identifier(), SL, cPositionInfo.TakeProfit() );
      }
    }
  }

  void TrailingsByRecentPrice(ENUM_POSITION_TYPE PositionType, ENUM_TIMEFRAMES priceTimeframe, int priceRange) {
    CTrade itrade;
    MyPrice myPrice(priceTimeframe, priceRange);
    myPrice.Refresh();
    for(int i = Total - 1; i >= 0; i--) {
      cPositionInfo.SelectByTicket(PositionGetTicket(i));
      if(cPositionInfo.PositionType() != PositionType) continue;
      if(cPositionInfo.Magic() != MagicNumber) continue;
      if(MathAbs(cPositionInfo.StopLoss() - cPositionInfo.PriceCurrent()) < 30 * _Point) continue;
      if(PositionType == POSITION_TYPE_BUY) {
        itrade.PositionModify(cPositionInfo.Identifier(), myPrice.Lowest(1, priceRange), cPositionInfo.PriceCurrent() + 30 * _Point );
      } else if(PositionType == POSITION_TYPE_SELL) {
        itrade.PositionModify(cPositionInfo.Identifier(), myPrice.Highest(1, priceRange), cPositionInfo.PriceCurrent() - 30 * _Point );
      }
    }
  }

  long CloseByPassedBars(ENUM_POSITION_TYPE PositionType, ENUM_TIMEFRAMES priceTimeframe, int barsCount) {
    for(int i = Total - 1; i >= 0; i--) {
      cPositionInfo.SelectByTicket(PositionGetTicket(i));
      if(cPositionInfo.PositionType() != PositionType) continue;
      if(cPositionInfo.Magic() != MagicNumber) continue;
      if(Bars(_Symbol, priceTimeframe, cPositionInfo.Time(), TimeCurrent()) > barsCount) {
        double dwad = cPositionInfo.Ticket();
        CloseEachPosition(cPositionInfo.Ticket());
      }
    }
    return 0;
  }



 private:
  CPositionInfo cPositionInfo;
};
//+------------------------------------------------------------------+
