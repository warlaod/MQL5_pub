#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

/////////////////////////////
bool isBetween(double top,double middle, double bottom) {

   if(top - bottom > 0 && top-middle > 0 && middle -bottom >0) return true;
   return false;
}

/////////////////////////////
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

/////////////////////////////
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
   
   void Refresh(){
      CopyRates(_Symbol, Timeframe, 0, count, price);
   }

   MqlRates getData(int index) {
      return price[index];
   }

   double Higest() {
      CopyHigh(_Symbol, Timeframe, 0, count, High);
      if(!High[count - 1]) {
         return NULL;
      }

      return price[ArrayMaximum(High, 0, count)].high;
   }

   double Lowest() {
      CopyLow(_Symbol, Timeframe, 0, count, Low);
      if(!Low[count - 1]) {
         return NULL;
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
   
   double RosokuBody(int index){
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


/////////////////////////////
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
input int spread = 99999;
input int denom = 30000;
input int positions = 2;
input bool isLotModified = false;
input int FridayEndHour = 23;

class MyTrade {

 public:
   bool istradable;
   string signal;
   double lot;
   double Ask;
   double Bid;
   double balance;
   MqlDateTime dt;

   void MyTrade() {
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
      if(SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) >= spread) {
         istradable = false;
      }
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
         if((dt.hour == 22 && dt.min > 0) || dt.hour >= 23) {
            istradable = false;
         }
      }
   }

   void CheckBalance() {
      if(NormalizeDouble(AccountInfoDouble(ACCOUNT_BALANCE), 1) < 2000) {
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

 private:
   void ModifyLot() {
      lot = NormalizeDouble(AccountInfoDouble(ACCOUNT_EQUITY) / denom, 2);
      if(lot < 0.01) lot = 0.01;
      else if(lot > 50) lot = 50;
   }

};