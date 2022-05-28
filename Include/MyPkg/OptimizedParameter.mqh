//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
enum optimizedTimeframes {
   _M1 = PERIOD_M1,
   _M3 = PERIOD_M3,
   _M5 = PERIOD_M5,
   _M10 = PERIOD_M10,
   _M15 = PERIOD_M15,
   _M30 = PERIOD_M30,
   _H1 = PERIOD_H1,
   _H2 = PERIOD_H2,
   _H4 = PERIOD_H4,
   _H6 = PERIOD_H6,
   _H12 = PERIOD_H12,
   _D1 = PERIOD_D1,
   _W1 = PERIOD_W1,
   _MN1 = PERIOD_MN1
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_TIMEFRAMES convertENUM_TIMEFRAMES(optimizedTimeframes timeFrame) {
   ENUM_TIMEFRAMES resp = _Period;
   switch(timeFrame) {
   case _M1:
      resp = PERIOD_M1;
      break;
   case _M3:
      resp = PERIOD_M3;
      break;
   case _M5:
      resp = PERIOD_M5;
      break;
   case _M10:
      resp = PERIOD_M10;
      break;
   case _M15:
      resp = PERIOD_M15;
      break;
   case _M30:
      resp = PERIOD_M30;
      break;
   case _H1:
      resp = PERIOD_H1;
      break;
   case _H2:
      resp = PERIOD_H2;
      break;
   case _H4:
      resp = PERIOD_H4;
      break;
   case _H6:
      resp = PERIOD_H6;
      break;
   case _H12:
      resp = PERIOD_H12;
      break;
   case _D1:
      resp = PERIOD_D1;
      break;
   case _W1:
      resp = PERIOD_W1;
      break;
   case _MN1:
      resp = PERIOD_MN1;
      break;
   }
   return(resp);
}
//+------------------------------------------------------------------+
