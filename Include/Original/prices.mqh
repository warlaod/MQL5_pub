//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2018, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double HighestPrice(string symbol, ENUM_TIMEFRAMES period, int count)
  {
   MqlRates PriceInformation[];
   ArraySetAsSeries(PriceInformation,true);

   CopyRates(_Symbol,period,0,count,PriceInformation);
   int HighestCandle;

   double High[];
   ArraySetAsSeries(High,true);

   CopyHigh(symbol,period,0,count,High);

   HighestCandle = ArrayMaximum(High,0,count);

   return PriceInformation[HighestCandle].high;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double LowestPrice(string symbol, ENUM_TIMEFRAMES period, int count)
  {
   MqlRates PriceInformation[];
   ArraySetAsSeries(PriceInformation,true);

   CopyRates(symbol,period,0,count,PriceInformation);
   int LowestCandle;

   double Low[];
   ArraySetAsSeries(Low,true);

   CopyLow(symbol,period,0,count,Low);

   LowestCandle = ArrayMinimum(Low,0,count);

   return PriceInformation[LowestCandle].low;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isTooBigSpread(int cant_trade_spread_line)
  {
   if(SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) >= cant_trade_spread_line)
     {
      return true;
     }
   return false;

  }
 
//+------------------------------------------------------------------+
