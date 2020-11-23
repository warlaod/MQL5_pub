//+------------------------------------------------------------------+
//|                                              15SimpleBuyStop.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
CTrade trade;

MqlRates PriceArray[];
double mySARArray[];

input double profit = 185;
input double stoploss = 20000;
string signal="";
input double TrailingTP=50;
input double TrailingSL=10;
input int period_num = 9;
input int signal_num= 2;
input double lot = 0.1;

void OnTick()
  {
   double Bid=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
   double Ask=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
   
   signal = "";
   
   ENUM_TIMEFRAMES period = Timeframe(period_num);
   
   ArraySetAsSeries(PriceArray,true);
   CopyRates(_Symbol,period,0,20,PriceArray);
   
   ArraySetAsSeries(mySARArray,true);
   int SARDefinition =iSAR(_Symbol,period,0.02,0.2);
   CopyBuffer(SARDefinition,0,0,20,mySARArray);
   
   CheckSignal();
   
   
   if(signal =="sell" && PositionsTotal()<= 4){
   	 trade.Sell(lot,NULL,Bid,Bid+stoploss*_Point,Bid-profit*_Point,NULL);
   }   
   if(signal =="buy" && PositionsTotal()<= 4){
   	trade.Buy(lot,NULL,Ask,Ask-stoploss*_Point,Ask+profit*_Point,NULL);
   }
   
   
   ModifyTrailingBuy(Bid);
   ModifyTrailingSell(Ask);
   
   

      
      
      
  
   Comment("The signal is:",signal);

  }
//+------------------------------------------------------------------+

void CheckSignal(){
	int buysignal = 0;
	int sellsignal = 0;
	double LastSARValue = NormalizeDouble(mySARArray[4], 5);
   
	for(int i=1; i<=3; i++){
   	double SARValue = NormalizeDouble(mySARArray[i], 5);
   	
   	if(LastSARValue > PriceArray[4].low){
   		if(SARValue < PriceArray[i].low){
   			buysignal++;
   		}
   	}
   	
		if(LastSARValue < PriceArray[4].high){
	   	if(SARValue > PriceArray[i].high){
	   		sellsignal++;
	   	}
	   }
   }
   
  	if(buysignal == signal_num){signal = "buy";}
  	if(sellsignal == signal_num){signal = "sell";}
}



void ModifyTrailingBuy(double Bid){
   
   for(int i=PositionsTotal()-1; i>=0; i--){
      string symbol = PositionGetSymbol(i);
      ulong PositionTicket=PositionGetInteger(POSITION_TICKET);
	   double CurrentTP = PositionGetDouble(POSITION_TP);
      
      if(_Symbol != symbol){return;}
      if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
	   	if(Bid > CurrentTP-TrailingTP*_Point){
	      	trade.PositionModify(PositionTicket,CurrentTP-TrailingSL*_Point,CurrentTP+TrailingTP*_Point);
	      }
      }
  	}
}

void ModifyTrailingSell(double Ask){
   
   for(int i=PositionsTotal()-1; i>=0; i--){
      string symbol = PositionGetSymbol(i);
      ulong PositionTicket=PositionGetInteger(POSITION_TICKET);
      double CurrentTP = PositionGetDouble(POSITION_TP);
 
      if(_Symbol != symbol){return;}
      if(PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_SELL){
      	if(Ask < CurrentTP+TrailingTP*_Point){
         	trade.PositionModify(PositionTicket,CurrentTP+TrailingSL*_Point,CurrentTP-TrailingTP*_Point);
         }
      }
   }
}



ENUM_TIMEFRAMES Timeframe(int period_num){
	if(period_num == 1){return PERIOD_M1;}
	if(period_num == 2){return PERIOD_M2;}
	if(period_num == 3){return PERIOD_M3;}
	if(period_num == 4){return PERIOD_M5;}
	if(period_num == 5){return PERIOD_M10;}
	if(period_num == 6){return PERIOD_M12;}
	if(period_num == 7){return PERIOD_M15;}
	if(period_num == 8){return PERIOD_M20;}
	if(period_num == 9){return PERIOD_M30;}
	if(period_num == 10){return PERIOD_H1;}
	if(period_num == 11){return PERIOD_H2;}
	if(period_num == 12){return PERIOD_H3;}
	if(period_num == 13){return PERIOD_H4;}
	if(period_num == 14){return PERIOD_H6;}
	if(period_num == 16){return PERIOD_H8;}
	if(period_num == 17){return PERIOD_H12;}
	if(period_num == 18){return PERIOD_D1;}
	if(period_num == 19){return PERIOD_W1;}
	return PERIOD_CURRENT;
}