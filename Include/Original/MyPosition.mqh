//+------------------------------------------------------------------+
//|                                                   MyPosition.mqh |
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
 if(Price[0].close < LowestPrice + HighLowDiff * HighLowCri) {
      range = "Lower";

   } else if(Price[0].close > HighestPrice - HighLowDiff * HighLowCri) {
      range = "Upeer";
      TotalPositions = MathRound((HighLowDiff * HighLowCri) / (ATR[0] * CornerPriceUnitCoef));
   } else if(Price[0].close > LowestPrice + HighLowDiff * HighLowCri && Price[0].close < HighestPrice - HighLowDiff * HighLowCri) {
      range = "Middle";
      TotalPositions = MathRound(((1 - 2 * HighLowCri) * HighLowDiff) / (ATR[0] * CoreRangePriceUnitCoef));
   }

   if(range == "Lower") {
      bottom = LowestPrice - SL * _Point;
      top = LowestPrice + HighLowDiff * HighLowCri;
      price_unit = ATR[0] * CornerPriceUnitCoef;
      TotalPositions = MathRound((top - bottom) / price_unit);

      string where = WherePositonIsInRange(price_unit, POSITION_TYPE_BUY);
      switch(where) {
      case 'Both':
         Print("CASE A");
         break;
      case 'Upper':
      case 'Lower':
         Print("CASE B or C");
         break;
      default:
         Print("NOT A, B or C");
         break;
      }