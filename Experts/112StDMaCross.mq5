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
CTrade trade;

string signal;
input int SL;
input int MIN;
input int denom;
input int positions;
input double TPbuy,SLbuy,TPsell,SLsell;
double lot = 0.10;
MqlDateTime dt;

int MAIndicatorShort,MAIndicatorLong;
input int MaParamShort,MAParamLong,MAPriceType,ma_method,MaPeriod;
double MAShort[],MALong[];


int ATRIndicator;
double ATR[];
input int ATRParam,ATRPeriod;
input double ATRCri;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   ENUM_MA_METHOD Ma_Mehod;
   switch(ma_method)
     {
      case 0:
         Ma_Mehod = MODE_SMA;
         break;
      case 1:
         Ma_Mehod = MODE_EMA;
         break;
      case 2:
         Ma_Mehod = MODE_SMMA;
         break;
      case 3:
         Ma_Mehod = MODE_LWMA;
         break;
     }
   MAIndicatorLong = iMA(_Symbol,Timeframe(MaPeriod),MaParamShort,0,Ma_Mehod,MAPriceType);
   MAIndicatorShort = iMA(_Symbol,Timeframe(MaPeriod),MaParamShort+MAParamLong,0,Ma_Mehod,MAPriceType);
   ArraySetAsSeries(MAShort,true);
   ArraySetAsSeries(MALong,true);

   ATRIndicator = iATR(_Symbol,Timeframe(ATRPeriod),ATRParam);
   ArraySetAsSeries(ATR,true);

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(isUntradable())
     {
      return;
     }
   lot =SetLot(denom);
   double Bid=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
   double Ask=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
   signal = "";
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   CopyBuffer(MAIndicatorShort,0,0,2,MAShort);
   CopyBuffer(MAIndicatorLong,0,0,2,MALong);
   CopyBuffer(ATRIndicator,0,0,1,ATR);

   if(ATR[0] < ATRCri)
     {
      return;
     }

   if(MALong[1] > MAShort[1] && MAShort[0] > MALong[0])
     {
      signal="buy";
     }
   else
      if(MALong[1] < MAShort[1] && MAShort[0] < MALong[0])
        {
         signal = "sell";
        }
   
   
   double pl = MAShort[0]*ATR[0];
   
   if(EachPositionsTotal("buy") < positions/2 && signal=="buy")
     {
      if(pl*TPbuy > 25*_Point && pl*SLbuy > SL*_Point)
        {
         trade.Buy(lot,NULL,Ask,pl*SLbuy,pl*TPbuy,NULL);
        }
     }

   if(EachPositionsTotal("sell") < positions/2 && signal=="sell")
     {
     if(pl*TPsell > 25*_Point && pl*SLsell > SL*_Point)
        {
         trade.Sell(lot,NULL,Bid,pl*SLsell,pl*TPsell,NULL);
        }
     }


  }
//+------------------------------------------------------------------+
double OnTester()
  {

   if(!setVariables())
     {
      return -99999999;
     }
   return testingScalp();

  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isUntradable()
  {
   TimeToStruct(TimeCurrent(),dt);
   if(dt.day_of_week == FRIDAY)
     {
      if((dt.hour == 22 && dt.min > MIN) || dt.hour == 23)
        {
         CloseAllBuyPositions();
         CloseAllSellPositions();
         return true;
        }
     }

   if(isTooBigSpread(2))
     {
      return true;
     }
   if(isNotEnoughMoney())
     {
      return true;
     }
   return false;
  }
//+------------------------------------------------------------------+
