//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

enum mis_MarcosTMP {
   _M1 = PERIOD_M1,
   _M5 = PERIOD_M5,
   _M15 = PERIOD_M15,
//   _M20=PERIOD_M20,
   _M30 = PERIOD_M30,
   _H1 = PERIOD_H1,
   _H2 = PERIOD_H2,
   _H4 = PERIOD_H4,
   _H8 = PERIOD_H8,
   _D1 = PERIOD_D1,
   _W1 = PERIOD_W1,
   _MN1 = PERIOD_MN1
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_TIMEFRAMES defMarcoTiempo(mis_MarcosTMP marco) {
   ENUM_TIMEFRAMES resp = _Period;
   switch(marco) {
   case _M1:
      resp = PERIOD_M1;
      break;
   case _M5:
      resp = PERIOD_M5;
      break;
   case _M15:
      resp = PERIOD_M15;
      break;
   //case _M20: resp= PERIOD_M20; break;
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
   case _H8:
      resp = PERIOD_H8;
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
