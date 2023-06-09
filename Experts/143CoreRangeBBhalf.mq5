//+------------------------------------------------------------------+
//|                                            1009ScalpFractals.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

#include <Trade\Trade.mqh>
input int MagicNumber = 0;

class MyUtils {
 public:
   int magicNum;
   int eventTime;
   void MyUtils(int eventTime = 0) {
      this.eventTime = eventTime;

   }
   void Init() {
      if(eventTime > 0) EventSetTimer(eventTime);
   }
};
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+


input int spread = -1;
input int denom = 30000;
input bool isLotModified = false;
input int FridayCloseHour = 23;
input int StopBalance = 2000;
input int StopMarginLevel = 200;

class MyTrade {

 public:
   bool istradable;
   string signal;
   double lot;
   double Ask;
   double Bid;
   double balance;
   double minlot;
   double maxlot;
   int LotDigits;
   MqlDateTime dt;

   void MyTrade() {
      minlot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
      maxlot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
      if(minlot == 0.001) LotDigits = 3;
      if(minlot == 0.01) LotDigits = 2;
      if(minlot == 0.1) LotDigits = 1;
      if(minlot == 1) LotDigits = 0;
      ModifyLot();
   }

   void Refresh() {
      if(isLotModified) ModifyLot();
      istradable = true;
      signal = "";
      Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
      Ask =  NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   }

   void CheckSpread() {
      int currentSpread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
      if(spread == -1)
         return;
      if(currentSpread >= spread)
         istradable = false;
   }

   bool isInvalidTrade(double SL, double TP) {
      if(TP > SL) {
         if(TP - Ask < 20 * _Point || Ask - SL < 20 * _Point) return true;
      }

      else if(TP < SL) {
         if(Bid - TP < 20 * _Point  || SL - Bid < 20 * _Point) return true;
      }
      return false;
   }

   void CheckUntradableTime(string start, string end) {
      if(isBetween(StringToTime(end), TimeCurrent(), StringToTime(start))) istradable = false;
   }
   
   void CheckTradableTime(string start, string end) {
      if(!isBetween(StringToTime(end), TimeCurrent(), StringToTime(start))) istradable = false;
   }

   void CheckYearsEnd() {
      TimeToStruct(TimeCurrent(), dt);
      if(dt.mon == 12 && dt.day > 25) {
         istradable =  false;
      }
      if(dt.mon == 1 && dt.day < 5) {
         istradable = false;
      }
   }

   void CheckFridayEnd() {
      TimeToStruct(TimeCurrent(), dt);
      if(dt.day_of_week == FRIDAY) {
         if((dt.hour == FridayCloseHour && dt.min > 30) || dt.hour >= FridayCloseHour) {
            istradable = false;
         }
      }
   }

   void CheckBalance() {
      if(NormalizeDouble(AccountInfoDouble(ACCOUNT_BALANCE), 1) < StopBalance) {
         istradable = false;
      }
   }

   void CheckMarginLevel() {
      double marginlevel = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
      if(marginlevel < StopMarginLevel && marginlevel != 0 ) istradable = false;
   }


 private:
   void ModifyLot() {
      lot = NormalizeDouble(AccountInfoDouble(ACCOUNT_EQUITY) / denom, LotDigits);
      if(lot < minlot) lot = minlot;
      else if(lot > maxlot) lot = maxlot;
   }

};
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                  MyCalculate.mqh |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
// #define MacrosHello   "Hello, world!"
// #define MacrosYear    2010
//+------------------------------------------------------------------+
//| DLL imports                                                      |
//+------------------------------------------------------------------+
// #import "user32.dll"
//   int      SendMessageA(int hWnd,int Msg,int wParam,int lParam);
// #import "my_expert.dll"
//   int      ExpertRecalculate(int wParam,int lParam);
// #import
//+------------------------------------------------------------------+
//| EX5 imports                                                      |
//+------------------------------------------------------------------+
// #import "stdlib.ex5"
//   string ErrorDescription(int error_code);
// #import
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isBetween(double top, double middle, double bottom) {

   if(top - bottom > 0 && top - middle > 0 && middle - bottom > 0) return true;
   return false;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double NewBarsCount(datetime LastTime, ENUM_TIMEFRAMES Timeframe) {
   return Bars(_Symbol, Timeframe, Timeframe, TimeCurrent());
}
//+------------------------------------------------------------------+


class MyPrice {
 public:
   int count ;
   ENUM_TIMEFRAMES Timeframe;
   void MyPrice(ENUM_TIMEFRAMES Timeframe, int count) {
      this.Timeframe = Timeframe;
      this.count = count;
      ArraySetAsSeries(price, true);
      ArraySetAsSeries(Low, true);
      ArraySetAsSeries(High, true);
   }

   void Refresh() {
      CopyRates(_Symbol, Timeframe, 0, count, price);
      if(ArraySize(price) < count) {
         CopyRates(_Symbol, _Period, 0, count, price);
         Comment("Warning: Now using current Timeframe due to shortage of bars");
      }
   }

   MqlRates At(int index) {
      return price[index];
   }

   double Higest(int start,int high_count) {
      CopyHigh(_Symbol, Timeframe, start, high_count, High);
      if(ArraySize(High) < high_count) {
         CopyHigh(_Symbol, _Period, 0, high_count, High);
         Comment("Warning: Now using current Timeframe due to shortage of bars");
      }
      return High[ArrayMaximum(High,0,high_count)];
   }

   double Lowest(int start,int low_count) {
      CopyLow(_Symbol, Timeframe, start, low_count, Low);
      if(ArraySize(Low) < low_count) {
         CopyLow(_Symbol, _Period, 0, low_count, Low);
         Comment("Warning: Now using current Timeframe due to shortage of bars");
      }
      return Low[ArrayMinimum(Low, 0, low_count)];
   }

   double RosokuHigh(int index) {
      if(RosokuIsPlus(index)) return  price[index].high - price[index].close;
      return  price[index].high - price[index].open;
   }

   double RosokuLow(int index) {
      if(RosokuIsPlus(index)) return  price[index].open - price[index].low;
      return  price[index].close - price[index].low;
   }

   double RosokuBody(int index) {
      return MathAbs( price[index].close - price[index].open );
   }

   bool RosokuIsPlus(int index) {
      bool PlusDirection = price[index].close > price[index].open ? true : false;
      return PlusDirection;
   }

 private:
   MqlRates price[];
   double High[];
   double Low[];
};
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                      MyOrder.mqh |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
// #define MacrosHello   "Hello, world!"
// #define MacrosYear    2010
//+------------------------------------------------------------------+
//| DLL imports                                                      |
//+------------------------------------------------------------------+
// #import "user32.dll"
//   int      SendMessageA(int hWnd,int Msg,int wParam,int lParam);
// #import "my_expert.dll"
//   int      ExpertRecalculate(int wParam,int lParam);
// #import
//+------------------------------------------------------------------+
//| EX5 imports                                                      |
//+------------------------------------------------------------------+
// #import "stdlib.ex5"
//   string ErrorDescription(int error_code);
// #import
//+------------------------------------------------------------------+
#include <Trade\OrderInfo.mqh>
#include <Trade\HistoryOrderInfo.mqh>

class MyOrder {
 public:
   int HistoryTotal;
   ENUM_TIMEFRAMES Timeframe;

   void MyOrder(ENUM_TIMEFRAMES Timeframe) {
      this.Timeframe = Timeframe;
   }

   void Refresh() {
      HistorySelect(0, TimeCurrent());
      HistoryTotal = HistoryOrdersTotal();
   }


   bool wasOrderedInTheSameBar() {
      CHistoryOrderInfo cHistoryOrderInfo;
      cHistoryOrderInfo.SelectByIndex(HistoryTotal - 1);
      if(cHistoryOrderInfo.Magic() != MagicNumber) return false;
      int current = TimeCurrent();
      int timedone = cHistoryOrderInfo.TimeDone();
      int bars = Bars(_Symbol, Timeframe, cHistoryOrderInfo.TimeDone(), TimeCurrent());
      if(Bars(_Symbol, Timeframe, cHistoryOrderInfo.TimeDone(), TimeCurrent()) == 0 )
         return true;
      return false;
   }

};
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

class MyPosition {
 public:
   MqlDateTime dt;
   int Total;

   void Refresh() {
      Total = PositionsTotal();
   }

   bool isPositionInRange(double Range, double CenterLine, ENUM_POSITION_TYPE PositionType) {
      for(int i = Total - 1; i >= 0; i--) {
         cPositionInfo.SelectByTicket(PositionGetTicket(i));
         if(cPositionInfo.PositionType() != PositionType) continue;
         if(cPositionInfo.Magic() != MagicNumber) continue;
         if(MathAbs(cPositionInfo.PriceOpen() - CenterLine) < Range) {
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

   void Trailings(ENUM_POSITION_TYPE PositionType, double SL) {
      CTrade itrade;
      for(int i = Total - 1; i >= 0; i--) {
         cPositionInfo.SelectByTicket(PositionGetTicket(i));
         if(cPositionInfo.PositionType() != PositionType) continue;
         if(cPositionInfo.Magic() != MagicNumber) continue;
         if(MathAbs(cPositionInfo.StopLoss() - cPositionInfo.PriceCurrent()) < MathAbs(SL - cPositionInfo.PriceCurrent())) continue;
         if(PositionType == POSITION_TYPE_BUY) {
            itrade.PositionModify(cPositionInfo.Identifier(), SL, cPositionInfo.PriceCurrent() + 50 * _Point );
         } else if(PositionType == POSITION_TYPE_SELL) {
            itrade.PositionModify(cPositionInfo.Identifier(), SL, cPositionInfo.PriceCurrent() - 50 * _Point );
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
            itrade.PositionModify(cPositionInfo.Identifier(), myPrice.Higest(1, priceRange), cPositionInfo.PriceCurrent() - 30 * _Point );
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

#include <Indicators\TimeSeries.mqh>
#include <Indicators\Oscilators.mqh>
#include <Indicators\Trend.mqh>
#include <Trade\OrderInfo.mqh>
CiOsMA ciOsma;
CiATR ciATR;
COrderInfo cOrderInfo;
CTrade trade;
CiBands ciBand;

input ENUM_TIMEFRAMES OsmaTimeframe, BandTimeframe;
input ENUM_APPLIED_PRICE OsmaAppliedPrice, BandAppliedPrice;

input double CornerCri;
input int PriceCount;
input int SLCorner, OsmaCri, RangeUnitCri;
input double SLCore, CornerPriceCri, RangePriceCri;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPrice myPrice(BandTimeframe, PriceCount);
MyPosition myPosition;
MyTrade myTrade();
MyOrder myOrder(BandTimeframe);

// ATR, bottom,top個別
int OnInit() {
   MyUtils myutils(60);
   myutils.Init();
   ciOsma.Create(_Symbol, OsmaTimeframe, 12, 25, 9, OsmaAppliedPrice);
   ciBand.Create(_Symbol, BandTimeframe, 20, 0, 2, BandAppliedPrice);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer() {
   myPrice.Refresh();
   myPosition.Refresh();
   myTrade.Refresh();
   ciOsma.Refresh();
   ciBand.Refresh();
   myTrade.CheckSpread();
   if(myOrder.wasOrderedInTheSameBar()) myTrade.istradable = false;
   if(!myTrade.istradable) return;


   double lowest_price = myPrice.Lowest(0, PriceCount);
   double highest_price = myPrice.Higest(0, PriceCount);
   double highest_lowest_range = highest_price - lowest_price;
   double current_price = myPrice.At(0).close;

   double bottom, top;
   double range_unit;

   if(MathAbs(ciOsma.Main(1)) > MathAbs(ciOsma.Main(0))) return;
   if(MathAbs(ciOsma.Main(0)) < OsmaCri * _Point) return;

   if(current_price < lowest_price + highest_lowest_range * CornerCri) {
      range_unit = MathAbs((ciBand.Upper(0) - ciBand.Lower(0)) / 2) * CornerPriceCri;
      bottom = lowest_price - SLCorner * _Point;

      if(range_unit < RangeUnitCri * _Point) return;

      if(myPosition.isPositionInTPRange(range_unit, current_price, POSITION_TYPE_BUY)) return;
      if(myTrade.isInvalidTrade(bottom, myTrade.Ask + range_unit)) return;
      if(ciOsma.Main(0) < 0) return;
      trade.Buy(myTrade.lot, NULL, myTrade.Ask, bottom, myTrade.Ask + range_unit, NULL);
   }


   else if(current_price > highest_price - highest_lowest_range * CornerCri) {
      range_unit = MathAbs((ciBand.Upper(0) - ciBand.Lower(0)) / 2) * CornerPriceCri;
      top = highest_price + SLCorner * _Point;

      if(range_unit < RangeUnitCri * _Point) return;

      if(myPosition.isPositionInTPRange(range_unit, current_price, POSITION_TYPE_SELL)) return;
      if(myTrade.isInvalidTrade(top, myTrade.Bid - range_unit)) return;
      if(ciOsma.Main(0) > 0) return;
      trade.Sell(myTrade.lot, NULL, myTrade.Bid, top, myTrade.Bid - range_unit, NULL);
   }

   else if(current_price > lowest_price + highest_lowest_range * CornerCri && current_price < highest_price - highest_lowest_range * CornerCri) {
      range_unit = MathAbs((ciBand.Upper(0) - ciBand.Lower(0)) / 2) * RangePriceCri;
      top = highest_price - highest_lowest_range * CornerCri + SLCore * highest_lowest_range;
      bottom = lowest_price + highest_lowest_range * CornerCri - SLCore * highest_lowest_range;

      if(range_unit < RangeUnitCri * _Point) return;

      if(ciOsma.Main(0) > 0) {
         if(myPosition.isPositionInTPRange(range_unit, current_price, POSITION_TYPE_BUY)) return;
         if(myTrade.isInvalidTrade(bottom, myTrade.Ask + range_unit)) return;
         trade.Buy(myTrade.lot, NULL, myTrade.Ask, bottom, myTrade.Ask + range_unit, NULL);
      }

      else if(ciOsma.Main(0) < 0) {
         if(myPosition.isPositionInTPRange(range_unit, current_price, POSITION_TYPE_SELL)) return;
         if(myTrade.isInvalidTrade(top, myTrade.Bid - range_unit)) return;
         trade.Sell(myTrade.lot, NULL, myTrade.Bid, top, myTrade.Bid - range_unit, NULL);
      }
   }


}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
