//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input bool debugMode;
enum LOG_LEVEL {
  Info,
  Warning,
  Error,
};
class Logger {
 public:
   string symbol;


   void Logger(string symbol) {
      this.symbol = symbol;
   };

   void Log(string message, LOG_LEVEL l) {
      string level = LogLevel(l);
      string current = TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS);
      string logBody = StringFormat("[%s][%s]:%s:", current, this.symbol, level) + message;

      if(debugMode) {
         Print(logBody);
      }
      Comment(logBody);
   }

   string LogLevel(LOG_LEVEL l) {
      switch(l) {
      case Info:
         return "Info";
      case Warning:
         return "Warning";
      case Error:
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
