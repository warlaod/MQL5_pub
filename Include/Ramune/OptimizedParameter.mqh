//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
enum optimizedTimeframes {
   _M2 = PERIOD_M2,
   _M4 = PERIOD_M4,
   _M6 = PERIOD_M6,
   _M12 = PERIOD_M12,
   _M20 = PERIOD_M20,
   _M30 = PERIOD_M30,
   _H1 = PERIOD_H1,
   _H2 = PERIOD_H2,
   _H3 = PERIOD_H3,
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
   case _M2:
      resp = PERIOD_M2;
      break;
   case _M4:
      resp = PERIOD_M4;
      break;
   case _M6:
      resp = PERIOD_M6;
      break;
   case _M12:
      resp = PERIOD_M12;
      break;
   case _M20:
      resp = PERIOD_M20;
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
   case _H3:
      resp = PERIOD_H3;
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
