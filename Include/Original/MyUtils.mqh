//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

#include <Trade\Trade.mqh>
input int MagicNumber = 0;

class MyUtils {
 public:
   int magicNum;
   int eventTime;
   void MyUtils(int eventTime = 0) {
      this.eventTime = eventTime;

   }
   void Init() {
      if(eventTime > 0) EventSetTimer(eventTime);
   }
};
//+------------------------------------------------------------------+
