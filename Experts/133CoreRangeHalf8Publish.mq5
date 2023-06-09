//+------------------------------------------------------------------+
//|                                            1009ScalpFractals.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.02"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

input int MagicNumber = 0;

class MyUtils{
   public:
      int magicNum;
      int eventTime;
      void MyUtils(int eventTime = 0){
         this.eventTime = eventTime;
         
      }
      void Init(){
         if(eventTime > 0) EventSetTimer(eventTime);
      }
      
};

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

   void CloseAllPositions(ENUM_POSITION_TYPE PositionType) {
      CTrade itrade;
      for(int i = Total - 1; i >= 0; i--) {
         cPositionInfo.SelectByTicket(PositionGetTicket(i));
         if(cPositionInfo.Magic() != MagicNumber) continue;
         if(cPositionInfo.PositionType() != PositionType) continue;
         itrade.PositionClose(PositionGetTicket(i));
      }
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

   void Trailings(ENUM_POSITION_TYPE PositionType,double SL) {
      CTrade itrade;
      for(int i = Total - 1; i >= 0; i--) {
         cPositionInfo.SelectByTicket(PositionGetTicket(i));
         if(cPositionInfo.PositionType() != PositionType) continue;
         if(cPositionInfo.Magic() != MagicNumber) continue;
         if(MathAbs(cPositionInfo.StopLoss() - cPositionInfo.PriceCurrent()) < MathAbs(SL-cPositionInfo.PriceCurrent())) continue;
         if(PositionType == POSITION_TYPE_BUY) {
            itrade.PositionModify(cPositionInfo.Identifier(),SL,cPositionInfo.PriceCurrent()+10*_Point );
         } else if(PositionType == POSITION_TYPE_SELL) {
            itrade.PositionModify(cPositionInfo.Identifier(),SL,cPositionInfo.PriceCurrent()-10*_Point );
         }
      }
   }
   
   void TrailingsByRecentPrice(ENUM_POSITION_TYPE PositionType,ENUM_TIMEFRAMES priceTimeframe, int priceRange) {
      CTrade itrade;
      MyPrice myPrice(priceTimeframe,priceRange);
      myPrice.Refresh();
      for(int i = Total - 1; i >= 0; i--) {
         cPositionInfo.SelectByTicket(PositionGetTicket(i));
         if(cPositionInfo.PositionType() != PositionType) continue;
         if(cPositionInfo.Magic() != MagicNumber) continue;
         if(MathAbs(cPositionInfo.StopLoss() - cPositionInfo.PriceCurrent()) < 30*_Point) continue;
         if(PositionType == POSITION_TYPE_BUY) {
            itrade.PositionModify(cPositionInfo.Identifier(),myPrice.Lowest(),cPositionInfo.PriceCurrent()+30*_Point );
         } else if(PositionType == POSITION_TYPE_SELL) {
            itrade.PositionModify(cPositionInfo.Identifier(),myPrice.Higest(),cPositionInfo.PriceCurrent()-30*_Point );
         }
      }
   }

 private:
   CPositionInfo cPositionInfo;
};
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

   MqlRates getData(int index) {
      return price[index];
   }

   double Higest() {
      CopyHigh(_Symbol, Timeframe, 0, count, High);
      if(ArraySize(High) < count) {
         CopyHigh(_Symbol, _Period, 0, count, High);
         Comment("Warning: Now using current Timeframe due to shortage of bars");
      }
      return price[ArrayMaximum(High, 0, count)].high;
   }

   double Lowest() {
      CopyLow(_Symbol, Timeframe, 0, count, Low);
      if(ArraySize(Low) < count) {
         CopyLow(_Symbol, _Period, 0, count, Low);
         Comment("Warning: Now using current Timeframe due to shortage of bars");
      }
      return price[ArrayMinimum(Low, 0, count)].low;
   }

   double RosokuHigh(int index) {
      if(RosokuDirection(index)) return  price[index].high - price[index].close;
      return  price[index].high - price[index].open;
   }

   double RosokuLow(int index) {
      if(RosokuDirection(index)) return  price[index].open - price[index].low;
      return  price[index].close - price[index].low;
   }

   double RosokuBody(int index) {
      return MathAbs( price[index].close - price[index].open );
   }

   double RosokuDirection(int index) {
      bool PlusDirection = price[index].close > price[index].open ? true : false;
      return PlusDirection;
   }

 private:
   MqlRates price[];
   double High[];
   double Low[];
};
//+------------------------------------------------------------------+


input int denom = 6000000;
input bool isLotModified = false;
input int FridayEndHour = 23;
input int StopBalance = 5000;
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
      TimeToStruct(TimeCurrent(), dt);
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

   void CheckYearsEnd() {
      if(dt.mon == 12 && dt.day > 25) {
         istradable =  false;
      }
      if(dt.mon == 1 && dt.day < 5) {
         istradable = false;
      }
   }

   void CheckFridayEnd() {
      if(dt.day_of_week == FRIDAY) {
         if((dt.hour == FridayEndHour && dt.min > 0) || dt.hour >= FridayEndHour) {
            istradable = false;
         }
      }
   }

   void CheckBalance() {
      if(NormalizeDouble(AccountInfoDouble(ACCOUNT_BALANCE), 1) < StopBalance) {
         istradable = false;
      }
   }

   void CheckUntradableHour(int &hours[]) {
      for(int i = 0; i < ArraySize(hours); i++) {
         if(dt.hour == hours[i]) {
            istradable = false;
            return;
         }
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
bool isBetween(double top,double middle, double bottom) {

   if(top - bottom > 0 && top-middle > 0 && middle -bottom >0) return true;
   return false;
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
#include <Indicators\TimeSeries.mqh>
#include <Indicators\Oscilators.mqh>
#include <Trade\OrderInfo.mqh>
CiOsMA ciOsma;
CiATR ciATR;
COrderInfo cOrderInfo;
CTrade trade;

ENUM_TIMEFRAMES OsmaTimeframe = PERIOD_MN1;
ENUM_TIMEFRAMES ATRTimeframe = PERIOD_H3;
ENUM_APPLIED_PRICE OsmaAppliedPrice = PRICE_TYPICAL;

double CornerCri = 0.36;
double CornerPriceUnitCoef = 3.2;
double CoreRangePriceUnitCoef = 1.6;

int PriceCount = 43;
int SLCorner = 500;
double SLCore = 0.48;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyPrice myPrice(PERIOD_MN1, PriceCount);
MyPosition myPosition;
MyTrade myTrade();

// ATR, bottom,top個別
int OnInit() {
   MyUtils myutils(60);
   myutils.Init();
   trade.SetExpertMagicNumber(MagicNumber);

   ciOsma.Create(_Symbol, OsmaTimeframe, 12, 25, 9, OsmaAppliedPrice);
   ciATR.Create(_Symbol, ATRTimeframe, 14);
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
   ciATR.Refresh();

   myTrade.CheckBalance();
   myTrade.CheckMarginLevel();
   if(!myTrade.istradable) return;
   double lowest_price = myPrice.Lowest();
   double highest_price = myPrice.Higest();
   double highest_lowest_range = highest_price - lowest_price;
   double current_price = myPrice.getData(0).close;

   double bottom, top;
   double range_unit;

   if(current_price < lowest_price + highest_lowest_range * CornerCri) {
      range_unit = MathAbs(ciATR.Main(0)) * CornerPriceUnitCoef;
      bottom = lowest_price - SLCorner * _Point;

      if(myPosition.isPositionInRange(range_unit, current_price, POSITION_TYPE_BUY)) return;
      if(myTrade.isInvalidTrade(bottom, myTrade.Ask + range_unit)) return;
      if(ciOsma.Main(0) < 0) return;
      trade.Buy(myTrade.lot, NULL, myTrade.Ask, bottom, myTrade.Ask + range_unit, NULL);
   }


   else if(current_price > highest_price - highest_lowest_range * CornerCri) {
      range_unit = MathAbs(ciATR.Main(0)) * CornerPriceUnitCoef;
      top = highest_price + SLCorner * _Point;

      if(myPosition.isPositionInRange(range_unit, current_price, POSITION_TYPE_SELL)) return;
      if(myTrade.isInvalidTrade(top, myTrade.Bid - range_unit)) return;
      if(ciOsma.Main(0) > 0) return;
      trade.Sell(myTrade.lot, NULL, myTrade.Bid, top, myTrade.Bid - range_unit, NULL);
   }

   else if(current_price > lowest_price + highest_lowest_range * CornerCri && current_price < highest_price - highest_lowest_range * CornerCri) {
      range_unit = MathAbs(ciATR.Main(0)) * CoreRangePriceUnitCoef;
      top = highest_price - highest_lowest_range * CornerCri + SLCore * highest_lowest_range;
      bottom = lowest_price + highest_lowest_range * CornerCri - SLCore * highest_lowest_range;

      if(ciOsma.Main(0) > 0) {
         if(myPosition.isPositionInRange(range_unit, current_price, POSITION_TYPE_BUY)) return;
         if(myTrade.isInvalidTrade(bottom, myTrade.Ask + range_unit)) return;
         trade.Buy(myTrade.lot, NULL, myTrade.Ask, bottom, myTrade.Ask + range_unit, NULL);
      }

      else if(ciOsma.Main(0) < 0) {
         if(myPosition.isPositionInRange(range_unit, current_price, POSITION_TYPE_SELL)) return;
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
