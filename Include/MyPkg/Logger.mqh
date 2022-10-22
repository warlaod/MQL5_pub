//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input bool debugMode;
class Logger {
 public:
   string symbol;

   void Logger(string symbol) {
      this.symbol = symbol;
   };

   void Log(string message, int logLevel) {
      string level = LogLevel(logLevel);
      string current = TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS);
      string logBody = StringFormat("[%s][%s]:%s:", current, this.symbol,level) + message;

      if(debugMode) {
         Print(logBody);
      } else {
         Comment(logBody);
      }
   }

   string LogLevel(int logLevel) {
      switch(logLevel) {
      case 1:
         return "Info";
      case 2:
         return "Warning";
      case 3:
         return "Error";
      default:
         return "Info";
      }

   }

};
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
