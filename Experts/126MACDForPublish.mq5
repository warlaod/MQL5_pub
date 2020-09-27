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
#include <Indicators\TimeSeries.mqh>
#include <Indicators\Oscilators.mqh>
#include <Indicators\Trend.mqh>
#include <Trade\OrderInfo.mqh>
#include <Arrays\ArrayDouble.mqh>
#include <Indicators\BillWilliams.mqh>
#include <Arrays\ArrayDouble.mqh>
CTrade trade;
CiMACD ciLongMACD, ciShortMACD;
CiATR ciATR;
ENUM_TIMEFRAMES MacdShortTimeframe = PERIOD_M15;
ENUM_TIMEFRAMES MacdLongTimeframe = PERIOD_H2;
ENUM_TIMEFRAMES ATRTimeframe = PERIOD_M5;
ENUM_APPLIED_PRICE MacdPriceType = PRICE_WEIGHTED;
bool tradable = false;

double TPCoef = 15;
double SLCoef = 11.25;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
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


//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

input int spread = -1;
input int denom = 3000000;
int positions = 2;
input bool isLotModified = false;
input int FridayEndHour = 23;
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
      TimeToStruct(TimeCurrent(), dt);
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

   double Higest(int start,int high_count) {
      CopyHigh(_Symbol, Timeframe, start, high_count, High);
      if(ArraySize(High) < high_count) {
         CopyHigh(_Symbol, _Period, 0, high_count, High);
         Comment("Warning: Now using current Timeframe due to shortage of bars");
      }
      return price[ArrayMaximum(High, 0, high_count)].high;
   }

   double Lowest(int start,int low_count) {
      CopyLow(_Symbol, Timeframe, start, low_count, Low);
      if(ArraySize(Low) < low_count) {
         CopyLow(_Symbol, _Period, 0, low_count, Low);
         Comment("Warning: Now using current Timeframe due to shortage of bars");
      }
      return price[ArrayMinimum(Low, 0, low_count)].low;
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
//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

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

   void CloseAllPositions(ENUM_POSITION_TYPE PositionType) {
      CTrade itrade;
      for(int i = Total - 1; i >= 0; i--) {
         cPositionInfo.SelectByTicket(PositionGetTicket(i));
         if(cPositionInfo.Magic() != MagicNumber) continue;
         if(cPositionInfo.PositionType() != PositionType) continue;
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
            itrade.PositionModify(cPositionInfo.Identifier(), myPrice.Lowest(1,priceRange), cPositionInfo.PriceCurrent() + 30 * _Point );
         } else if(PositionType == POSITION_TYPE_SELL) {
            itrade.PositionModify(cPositionInfo.Identifier(), myPrice.Higest(1,priceRange), cPositionInfo.PriceCurrent() - 30 * _Point );
         }
      }
   }

   long CloseByPassedBars(ENUM_POSITION_TYPE PositionType, ENUM_TIMEFRAMES priceTimeframe, int barsCount) {
      for(int i = Total - 1; i >= 0; i--) {
         cPositionInfo.SelectByTicket(PositionGetTicket(i));
         if(cPositionInfo.PositionType() != PositionType) continue;
         if(cPositionInfo.Magic() != MagicNumber) continue;
         double wdadw = cPositionInfo.Time();
         double dwadwad = TimeCurrent();
         double fad = Bars(_Symbol, priceTimeframe, cPositionInfo.Time(), TimeCurrent());
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










MyPosition myPosition;
MyTrade myTrade;

int OnInit() {
   MyUtils myutils(60 * 27);
   myutils.Init();
   trade.SetExpertMagicNumber(MagicNumber);
   
   ciLongMACD.Create(_Symbol,MacdLongTimeframe,12,26,9,MacdPriceType);
   ciShortMACD.Create(_Symbol,MacdShortTimeframe,12,26,9,MacdPriceType);
   ciATR.Create(_Symbol, ATRTimeframe, 14);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   myPosition.Refresh();
   ciLongMACD.Refresh();
   ciShortMACD.Refresh();
   ciATR.Refresh();
   myTrade.Refresh();
   
   if(MacdShortTimeframe >= MacdLongTimeframe) return;
   
   myTrade.CheckSpread();
   if(!myTrade.istradable || !tradable) return;


   double LongHistogram[2];
   double ShortHistogram[2];
   for(int i=0; i<2; i++)
     {
      LongHistogram[i] = ciLongMACD.Main(i) - ciLongMACD.Signal(i);
      ShortHistogram[i] = ciShortMACD.Main(i) - ciShortMACD.Signal(i);
     }

   if(LongHistogram[0] > 0 && ciLongMACD.Main(0) > 0)
     {
      myTrade.signal ="buybuy";
     }
   else
      if(LongHistogram[0] < 0 && ciLongMACD.Main(0) < 0)
        {
         myTrade.signal ="sellsell";
        }

   if(ShortHistogram[1] < 0 && ShortHistogram[0] > 0 && ciShortMACD.Main(0) < 0 && myTrade.signal == "buybuy")
     {
      myTrade.signal = "buy";
     }
   else
      if(ShortHistogram[1] > 0 && ShortHistogram[0] < 0 && ciShortMACD.Main(0) > 0 && myTrade.signal == "sellsell")
        {
         myTrade.signal = "sell";
        }

    double PriceUnit = ciATR.Main(0);
   if(myPosition.TotalEachPositions(POSITION_TYPE_BUY) < positions / 2 && myTrade.signal == "buy") {
      if(myTrade.isInvalidTrade(myTrade.Ask - PriceUnit * SLCoef, myTrade.Ask + PriceUnit  * TPCoef)) return;
      trade.Buy(myTrade.lot, NULL, myTrade.Ask, myTrade.Ask - PriceUnit * SLCoef, myTrade.Ask + PriceUnit  * TPCoef, NULL);
   }

   if(myPosition.TotalEachPositions(POSITION_TYPE_SELL) < positions / 2 && myTrade.signal == "sell") {
      if(myTrade.isInvalidTrade(myTrade.Bid + PriceUnit * SLCoef, myTrade.Bid - PriceUnit * TPCoef)) return;
      trade.Sell(myTrade.lot, NULL, myTrade.Bid, myTrade.Bid + PriceUnit * SLCoef, myTrade.Bid - PriceUnit * TPCoef, NULL);
   }


}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer() {
   myPosition.Refresh();
   myTrade.Refresh();

   tradable = true;

   myTrade.CheckFridayEnd();
   myTrade.CheckYearsEnd();
   myTrade.CheckBalance();
   myTrade.CheckMarginLevel();

   if(!myTrade.istradable) {
      myPosition.CloseAllPositions(POSITION_TYPE_BUY);
      myPosition.CloseAllPositions(POSITION_TYPE_SELL);
      tradable = false;
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

//+------------------------------------------------------------------+
