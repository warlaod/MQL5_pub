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
#include <Original\prices.mqh>
#include <Original\positions.mqh>
#include <Original\period.mqh>
#include <Original\account.mqh>
#include <Original\Ontester.mqh>
#include <Original\caluculate.mqh>
CTrade trade;

MqlDateTime dt;
MqlRates Price[];
input int MIN;
input int positions = 2;
input int denom = 30000;
input int spread;
double lot = 0.10;
double  Bid, Ask;
bool tradable = false;
string signal;

int RSILongIndicator, RSIShortIndicator;
double RSIShort[], RSILong[];
input ENUM_TIMEFRAMES RSITimeframe;
input int RSILongPeriod, RSIShortPeriod, RSICri;
input ENUM_APPLIED_PRICE RSI_Applied_price;

int ATRIndicator;
input double SLCoef, TPCoef;
double ATR[];

input int i;


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   EventSetTimer(300);
   RSILongIndicator = iRSI(_Symbol, RSITimeframe, RSILongPeriod, RSI_Applied_price);
   RSIShortIndicator = iRSI(_Symbol, RSITimeframe, RSIShortPeriod, RSI_Applied_price);
   ATRIndicator = iATR(_Symbol, RSITimeframe, 14);

   ArraySetAsSeries(RSILong, true);
   ArraySetAsSeries(RSIShort, true);
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {

   Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);

   CopyBuffer(RSIShortIndicator, 0, 0, 3, RSIShort);
   CopyBuffer(RSILongIndicator, 0, 0, 3, RSILong);
   CopyBuffer(ATRIndicator, 0, 0, 1, ATR);

   if(tradable == false || isTooBigSpread(spread)) return;

   signal = "";

   if(RSILong[i] >  100 - RSICri || RSILong[i] < RSICri) return;

   if(RSILong[i + 1] - RSIShort[i + 1] > 0 && RSILong[i] - RSIShort[i] < 0) {
      signal = "sell";
   } else if(RSILong[i + 1] - RSIShort[i + 1] < 0 && RSILong[i] - RSIShort[i] > 0) {
      signal = "buy";
   }

   if(EachPositionsTotal("buy") < positions / 2 && signal == "buy") {
      if(!isNotInvalidTrade( Ask - ATR[0]*SLCoef, Ask + ATR[0]*TPCoef, Ask, true)) return;
      trade.Buy(lot, NULL, Ask, Ask - ATR[0]*SLCoef, Ask + ATR[0]*TPCoef, NULL);
   }

   if(EachPositionsTotal("sell") < positions / 2 && signal == "sell") {
      if(!isNotInvalidTrade( Bid + ATR[0]*SLCoef, Bid - ATR[0]*TPCoef, Bid, false)) return;
      trade.Sell(lot, NULL, Bid, Bid + ATR[0]*SLCoef, Bid - ATR[0]*TPCoef, NULL);
   }

}
//+------------------------------------------------------------------+
double OnTester() {
   if(!setVariables()) {
      return -99999999;
   }
   return testingNormal();

}
//+------------------------------------------------------------------+
void OnTimer() {
//lot = SetLot(denom);
   tradable  = true;
//lot =SetLot(denom);
   if(isNotEnoughMoney()) {
      tradable = false;
      return;
   }

   TimeToStruct(TimeCurrent(), dt);
   if(dt.day_of_week == FRIDAY) {
      if((dt.hour == 22 && dt.min > 0) || dt.hour == 23) {
         CloseAllBuyPositions();
         CloseAllSellPositions();
         tradable = false;
         return;
      }
   }

   if(isYearEnd(dt.mon, dt.day)) {
      tradable = false;
      return;
   }
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
