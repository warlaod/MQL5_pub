//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
struct tradeRequest {
   string symbol;
   ulong magicNumber;
   ENUM_ORDER_TYPE              type;             // 注文の種類
   double                       openPrice;           // Price for limit or stop order execution
   double                       sl;               // 注文の決済逆指値レベル
   double                       tp;               // 注文の決済指値レベル
   double                       bidOrAsk;       // Bid or Ask
   double                       volume;           // 約定のための要求されたボリューム（ロット単位）
   
};
//+------------------------------------------------------------------+
