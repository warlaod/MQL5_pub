//+-------------------------------------------------------------------+
//|                                         　　     musasabi_sama.mq5  |
//|                                                      musasabi fx  |
//|                             　http://musasabifx.hatenablog.jp  /   |
//+-------------------------------------------------------------------+
#property copyright "musasabi fx"
#property link      "http://musasabifx.hatenablog.jp/"
#property version   "1.00"



//----------------AccountNumber-------------

int Account_Number = 0;

//-------------------------------------------




input double Slippage=30;

input double Lots = 0.1;
input double TakeProfit=0;  
input double StopLoss = 0;     



input int Long_Entry_Heiken_Ashi_Bars = 2;
input int Short_Entry_Heiken_Ashi_Bars = 2;
input int Long_Close_Heiken_Ashi_Bars = 1;
input int Short_Close_Heiken_Ashi_Bars = 1;


datetime GlobalBar_Time = NULL;

datetime StartBars_Time = NULL;



int BuyBars = NULL;
int SellBars = NULL;

bool Buy_AllClose_Flag = false;
bool Sell_AllClose_Flag = false;

bool Buy_Entry_Flag = false;
bool Sell_Entry_Flag = false;

bool IsExpertEnabled_Flag = false;

string msg = "";


//指標ハンドルを入れる変数
int h_heiken_ashi = NULL;

int h_Arrow = NULL;

double Heiken_Ashi_Open_Val[];
double Heiken_Ashi_Close_Val[];

int Heiken_Ashi_Max_Bars = NULL;

bool Comment_Flag = false;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
  
  
   //初期化用関数
   Initialization();
  
   Heiken_Ashi_Max_Bars = Long_Entry_Heiken_Ashi_Bars;
   if( Heiken_Ashi_Max_Bars <= Short_Entry_Heiken_Ashi_Bars ) Heiken_Ashi_Max_Bars = Short_Entry_Heiken_Ashi_Bars;
   if( Heiken_Ashi_Max_Bars <= Long_Close_Heiken_Ashi_Bars ) Heiken_Ashi_Max_Bars = Long_Close_Heiken_Ashi_Bars;
   if( Heiken_Ashi_Max_Bars <= Long_Entry_Heiken_Ashi_Bars ) Heiken_Ashi_Max_Bars = Long_Entry_Heiken_Ashi_Bars;
   
   
   
     
  
   StartBars_Time = Time_Function(0);
   
   //MAのハンドル取得
   h_heiken_ashi = iCustom(NULL,0,"Examples\\Heiken_Ashi");
   
   
   //配列の時系列化
   ArraySetAsSeries(Heiken_Ashi_Open_Val, true);
   ArraySetAsSeries(Heiken_Ashi_Close_Val, true);

   
  
   DatePrint("init");
//---
   return(0);
  }


  
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

   Comment("");

   //指標の解放
   IndicatorRelease(h_heiken_ashi);
   
      
   DatePrint("deinit");
   
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---


   //アカウント指定
   if( AccountSpecification() == false )
   {   
      Comment("アカウントが指定アカウントと一致しないためEAを停止します。");
      
      Comment_Flag = true;
      
      return;
   }



   //自動売買スイッチがoffだったら
   if( TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) == false && MQLInfoInteger(MQL_TESTER) == false )
   {
      //初期化用関数
      Initialization();
      
      StartBars_Time = Time_Function(0);
      
      Comment("自動売買がOFFになっているためEAを停止します。");
      
      Comment_Flag = true;
   
      return;
   }
   
   
   if( SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN) > Lots )
   {
      Comment("Lotsがエントリー可能な最小ロット数を下回っていますのでEAを停止します。"+
            "\n"+Symbol()+"の最小ロット数は "+(string)SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN)+" ロットになります。");
      
      Comment_Flag = true;
      
      return;
   }
   
   
   if(   ((SymbolInfoInteger(Symbol(),SYMBOL_TRADE_STOPS_LEVEL) * Point()) > TakeProfit && TakeProfit != NULL)
      || ((SymbolInfoInteger(Symbol(),SYMBOL_TRADE_STOPS_LEVEL) * Point()) > StopLoss && StopLoss != NULL)
    )
   {
      Comment("TakeProfitかStopLossのどちらかがストップレベル未満のためEAを停止します。"+
            "\n"+Symbol()+"のストップレベルは "+(string)(SymbolInfoInteger(Symbol(),SYMBOL_TRADE_STOPS_LEVEL) * Point())+" になりますが"+
            "\n"+"スプレッドも関係ありますのでストップレベル以上の設定でもオーダーが通らない場合があります。\nスプレッドも含めた上で余裕のある数値を設定して下さい。");
      
      Comment_Flag = true;
      
      return;
   }
   
   
   
   
   if( Comment_Flag == true ) 
   {
      Comment("");
   
      Comment_Flag = false;
   }


   //インジケーターのデータのコピー
   Indicators_Val_Copy();


   MainCloseSystem(2500);

    //エントリーの処理
   MainEntrySystem(2500);


   GlobalBar_Time = Time_Function(0);
   
   
   

}
  
  



/*------------------------------------------------------
関数名   MainEntrySystem
内容     シグナルのエントリー処理を行う関数

引数     int MN   マジックナンバー

戻り値　 なし

-------------------------------------------------------*/
int MainEntrySystem(int MN)
{
   int cnt = NULL;

   
   ulong ticket = NULL;
   int magic_nm = NULL;
   string symbol_ = NULL;
   
   int err = NULL;
   int j = NULL;
   
   
   //オーダー番号を入れる変数
   int odtypeA = -1;
   
   
   
     
   //エントリー用の構造体の用意
   MqlTradeRequest request={0};
   MqlTradeResult result={0};
   MqlTick tick;

   //オーダーチェック
   //ポジション用
   for(cnt=PositionsTotal()-1; cnt>=0; cnt--)
   {
      ticket = PositionGetTicket(cnt);
      
      if(PositionSelectByTicket(ticket))
      {
      
      
         //lots = PositionGetDouble(POSITION_VOLUME);
         magic_nm = (int)PositionGetInteger(POSITION_MAGIC);
         symbol_ = PositionGetString(POSITION_SYMBOL);
      
         if( magic_nm == MN && Symbol() == symbol_ )
         {
            if( PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY
               || PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL )
            {
               odtypeA = cnt;
            }
         }
      
      }
      
   }

   


   if( odtypeA == -1 )
   {
   
      Buy_AllClose_Flag = false;
      Sell_AllClose_Flag = false;
      
   }
   
   if( Buy_AllClose_Flag == true || Sell_AllClose_Flag == true ) return(0);   


   

   //OpenPricesModeのチェック
   if(  ( StartBars_Time != Time_Function(0) && GlobalBar_Time != Time_Function(0) )
    )
   {
   
   
         
      if( odtypeA == -1 )
      {
      
         if( Buy_Entry_Flag == false && Sell_Entry_Flag == false )
         {
            if( BuySignal() == 1 ) Buy_Entry_Flag = true;
         }
         
         if( Buy_Entry_Flag == false && Sell_Entry_Flag == false )
         {
            if( SellSignal() == 2 ) Sell_Entry_Flag = true;
         }
      }

      
   }   
   
   
   
   

   
   if( Buy_Entry_Flag == true )
   {
      //レートデータを構造体に取得
      SymbolInfoTick(_Symbol, tick);
      
      
      request.action = TRADE_ACTION_DEAL; //トレードのアクション
      request.symbol = _Symbol;  //通貨ペア
      request.volume = Lots;  //ロット
      request.price = tick.ask;  //プライス
      
      if( Point() != NULL )
      {
         request.deviation = (int)((double)Slippage / (double)Point());
      }
      else
      {
         request.deviation = (int)Slippage;
      }
      
      
      request.magic = MN;  //マジックナンバー
      
      if( TakeProfit != NULL ) request.tp = NormalizeDouble(request.price + TakeProfit,Digits()); //リミット
      if( StopLoss != NULL )request.sl = NormalizeDouble(request.price - StopLoss,Digits());   //ストップロス
      
      request.type = ORDER_TYPE_BUY;   //オーダータイプ
      request.type_filling = ORDER_FILLING_FOK; //証券会社のエントリーの仕様の指定
      
      bool zzz = OrderSend(request,result);  //左の構造体でオーダーを出し、右の構造体に結果を取得
   
      //オーダーが約定していたら
      if( result.order != NULL && result.order != EMPTY_VALUE )
      {
         Buy_Entry_Flag = false;
      }      
      else
      {
         PrintFormat("OrderSend error %d",GetLastError());     // リクエストの送信が失敗した場合、エラーコードを出力する
         //--- 操作に関する情報
         PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
      }   
   }
   
   
   if( Sell_Entry_Flag == true )
   {

      SymbolInfoTick(_Symbol, tick);
      request.action = TRADE_ACTION_DEAL;
      request.symbol = _Symbol;
      request.volume = Lots;
      request.price = tick.bid;
      
      if( Point() != NULL )
      {
         request.deviation = (int)((double)Slippage / (double)Point());
      }
      else
      {
         request.deviation = (int)Slippage;
      }
      
      request.magic = MN;
      
      if( TakeProfit != NULL ) request.tp = NormalizeDouble(request.price - TakeProfit,Digits());
      if( StopLoss != NULL ) request.sl = NormalizeDouble(request.price + StopLoss,Digits());
      
      request.type = ORDER_TYPE_SELL;
      request.type_filling = ORDER_FILLING_FOK;
      
      
      
      bool zzz = OrderSend(request,result);
   
   
      if( result.order != NULL && result.order != EMPTY_VALUE )
      {
         Sell_Entry_Flag = false;
      }      
      else
      {
         PrintFormat("OrderSend error %d",GetLastError());     // リクエストの送信が失敗した場合、エラーコードを出力する
         //--- 操作に関する情報
         PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
      }   
   }
   
   
   
   
   
      
      
   return(0);
}








/*------------------------------------------------------
関数名   MainCloseSystem
内容     シグナルの決済処理を行う関数

引数     int MN   マジックナンバー

戻り値　 なし

-------------------------------------------------------*/
int MainCloseSystem(int MN)
{
   int cnt;
   
   //オーダー番号を入れる変数
   int odtypeA = -1;
     
   
   
   ulong ticket = NULL;
   int magic_nm = NULL;
   string symbol_ = NULL;
   
   double lots = NULL;
   for(cnt=PositionsTotal()-1; cnt>=0; cnt--)
   {
      ticket = PositionGetTicket(cnt);
      
      if(PositionSelectByTicket(ticket))
      {
      
      
         //lots = PositionGetDouble(POSITION_VOLUME);
         magic_nm = (int)PositionGetInteger(POSITION_MAGIC);
         symbol_ = PositionGetString(POSITION_SYMBOL);
      
         if( magic_nm == MN && Symbol() == symbol_ )
         {
            if( PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY
               || PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL )
            {
               odtypeA = cnt;
              
            }
         }
      
      }
      
   }
   
   



   if( odtypeA == -1 )
   {
   
      Buy_AllClose_Flag = false;
      Sell_AllClose_Flag = false;
      
      return(0);
   }
   

   //OpenPricesModeのチェック
   if(  ( StartBars_Time != Time_Function(0) && GlobalBar_Time != Time_Function(0) )
    )
   {
   
      if( odtypeA != -1 )
      {
   
         if( Sell_AllClose_Flag == false )
         {
            if( CloseSignal(odtypeA) == 1 ) 
            {
               Sell_AllClose_Flag = true;
      
               if( BuySignal() == 1 && BuyBars != Time_Function(0))Buy_Entry_Flag = true;
      
            }
         }
         
         
         if( Buy_AllClose_Flag == false )
         {
            if( CloseSignal(odtypeA) == 2 ) 
            {
               Buy_AllClose_Flag = true;
      
               if( SellSignal() == 2 && SellBars != Time_Function(0))Sell_Entry_Flag = true;
            }
         }   
      }

   }   
   
   
   if( Buy_AllClose_Flag == true ) AllClose(MN,"Buy");
   if( Sell_AllClose_Flag == true ) AllClose(MN,"Sell");
   
   
   
   
      
      
   return(0);
}







/*------------------------------------------------------
関数名   BuySignal
内容     買いシグナルの判定を行う関数

        
戻り値　 0:不成立　1:買いシグナル成立　

-------------------------------------------------------*/
int BuySignal()
{
   //もし買いシグナルが出ていたら
   if( Heiken_Ashi_Signal(Long_Entry_Heiken_Ashi_Bars,POSITION_TYPE_BUY) == 1)
   {
      //買いシグナル成立
      return(1);
   }
   
 
   return(0);
}




/*------------------------------------------------------
関数名   SellSignal
内容     売りシグナルの判定を行う関数

        
戻り値　 0:不成立　2:売りシグナル成立
-------------------------------------------------------*/
int SellSignal()
{

   
   //もし売りシグナルが出ていたら
   if( Heiken_Ashi_Signal(Short_Entry_Heiken_Ashi_Bars,POSITION_TYPE_SELL) == 2 )
   {      
      
      //売りシグナル成立
      return(2);
            
   }

   return(0);
}









/*------------------------------------------------------
関数名   CloseSignal
内容     決済時の売買シグナルの判定を行う関数

引数     int od    ポジション番号

        
戻り値　 0:不成立　1:売りポジションの決済シグナル成立　
       2:買いポジションの決済シグナル成立
-------------------------------------------------------*/
int CloseSignal(int od)
{
   ulong ticket = NULL;
   int magic_nm = NULL;
   string symbol_ = NULL;

   
   // ポジション無し
   if(od == -1)
   {}
   else
   {
      
      //オーダーセレクト
      ticket = PositionGetTicket(od);
      
      if(PositionSelectByTicket(ticket))
      {
      
         symbol_ = PositionGetString(POSITION_SYMBOL);
      
         //もし通貨が同じなら 
         if( Symbol() == symbol_ )
         {
            //もし買いポジションなら
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
            {
               if( Heiken_Ashi_Signal(Long_Close_Heiken_Ashi_Bars,POSITION_TYPE_SELL) == 2 )
               {
               
                  //買いポジションの決済シグナル成立　
                  return(2);
      
               } 
            
            }
                              
            //もし売りポジションなら
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
            {
            
               if( Heiken_Ashi_Signal(Short_Close_Heiken_Ashi_Bars,POSITION_TYPE_BUY) == 1 )
               {
               
                  //売りポジションの決済シグナル成立　
                  return(1);
      
               }
            
            }
         }   
      }
   }  
   

 
   return(0);
}





/*------------------------------------------------------
関数名   AllClose
内容     全ポジションを決済する関数

引数     int MN   マジックナンバー
         string type  "Buy": 買いポジション決済
                      "Sell":売りポジション決済
         

-------------------------------------------------------*/
int AllClose(int MN,string type)
{


   bool close_ticket_ = false;

   int j = NULL;

   int i = NULL;   
   
   ulong ticket = NULL;

   
   MqlTradeRequest request={0};
   MqlTradeResult result={0};
   MqlTick tick;
   
   
   
   for(i=PositionsTotal()-1; i>=0; i--)
   {
      
      
      ticket = PositionGetTicket(i);
      
      if(PositionSelectByTicket(ticket))
      {
      
         if((int)PositionGetInteger(POSITION_MAGIC) == MN)
         {
         
            if (PositionGetString(POSITION_SYMBOL) == Symbol()) 
            {
         
               //もし買いポジションなら
               if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY && type == "Buy")
               {
            
                  for( j=0;j<10;j++ )
                  {
                  
                  
                     SymbolInfoTick(_Symbol, tick);
                     request.action = TRADE_ACTION_DEAL;
                     request.symbol = _Symbol;
                     request.price = tick.bid;
                     
                     if( Point() != NULL )
                     {
                        request.deviation = (int)((double)Slippage / (double)Point());
                     }
                     else
                     {
                        request.deviation = (int)Slippage;
                     }
                     
                     request.magic = MN;
                     
                     request.type =ORDER_TYPE_SELL;
                     request.type_filling = ORDER_FILLING_FOK;
                     
                     request.position =ticket;
                     request.volume   =PositionGetDouble(POSITION_VOLUME);
                     request.magic    =MN;

                     //--- close position
                     close_ticket_ = OrderSend(request,result);
   
   
                     if( result.order != NULL && result.order != EMPTY_VALUE )
                     {
                        break;
                     }      

                  }         
               }                     
               //もし売りポジションなら
               if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL && type == "Sell")
               {
               
            
                  for( j=0;j<10;j++ )
                  {
                  
                  
                     SymbolInfoTick(_Symbol, tick);
                     request.action = TRADE_ACTION_DEAL;
                     request.symbol = _Symbol;
                     request.price = tick.ask;
                     
                     if( Point() != NULL )
                     {
                        request.deviation = (int)((double)Slippage / (double)Point());
                     }
                     else
                     {
                        request.deviation = (int)Slippage;
                     }
                     
                     request.magic = MN;
                     request.type =ORDER_TYPE_BUY;
                     request.type_filling = ORDER_FILLING_FOK;
                     
                     request.position =ticket;
                     request.volume   =PositionGetDouble(POSITION_VOLUME);
                     request.magic    =MN;

                     //--- close position
                     close_ticket_ = OrderSend(request,result);
   
   
                     if( close_ticket_ == true )
                     {
                        break;
                     }      

                  }         
               }                     
            
               
        
         
            }
         }
      }
   }

   
   
   return(0);
}








/*------------------------------------------------------
関数名   Heiken_Ashi_Signal
内容     MAのゴールデンクロスとデッドクロスを判断する関数

引数     int heiken_ashi_bars シグナルに必要なバーの数
         int type POSITION_TYPE_BUY:買いエントリー、もしくは売り決済
                 POSITION_TYPE_SELL;売りエントリー、もしくは買い決済
         
戻り値   0:何も出来ていない　1:ゴールデンクロス
        2:デッドクロス
         
         
        
-------------------------------------------------------*/
int Heiken_Ashi_Signal(int heiken_ashi_bars,int type)
{


   int i = NULL;
   
   int bars_type = NULL;//1なら陽線、2なら陰線
   
   double open_value = NULL;
   double close_value = NULL;
   
   
   for( i=1;i<=heiken_ashi_bars+1;i++ )
   {
   
      open_value = Heiken_Ashi_Open_Val[i];
      close_value = Heiken_Ashi_Close_Val[i];
      
      Shisyagonyuu(open_value,Digits());
      Shisyagonyuu(close_value,Digits());
   
      if( close_value >= open_value ) bars_type = 1;
      else bars_type = 2;
   
      if( i == heiken_ashi_bars+1 )
      {
         if( type == POSITION_TYPE_BUY && bars_type == 1 ) return(0);
         if( type == POSITION_TYPE_SELL && bars_type == 2 ) return(0);
      }
      else
      {
         if( type == POSITION_TYPE_BUY && bars_type == 2 ) return(0);
         if( type == POSITION_TYPE_SELL && bars_type == 1 ) return(0);
      }
   }

   if( type == POSITION_TYPE_BUY ) return(1);
   if( type == POSITION_TYPE_SELL ) return(2);

   return(0);
}






/*------------------------------------------------------
関数名   Shisyagonyuu
内容     特定の小数点の桁で四捨五入する関数
         valueに入れた変数が四捨五入されて戻る

引数     double& value 数値
         int keta 桁
         
戻り値   なし

-------------------------------------------------------*/
void Shisyagonyuu(double& value,int keta)
{

   int aaa = NULL;
   
   if( value != EMPTY_VALUE )
   {
      if( keta != NULL )
      {
         //指定の桁まで整数にして四捨五入にする
         aaa = (int)MathRound( value * ( MathPow( 10, keta)  ));
         
         //元の小数点の位置まで戻す
         value =  aaa * ( MathPow( 0.1, keta)  );
      }
      else
      {
         value = MathRound(value);
      }
   }
   
   value = NormalizeDouble(value,keta);
   
}









/*------------------------------------------------------
関数名   Initialization
内容     初期化用関数

引数     なし

戻り値　 なし

-------------------------------------------------------*/
void Initialization()
{


   //全ての変数の初期化
   GlobalBar_Time = NULL;
   StartBars_Time = NULL;
   BuyBars = NULL;
   SellBars = NULL;
   Buy_AllClose_Flag = false;
   Sell_AllClose_Flag = false;
   Buy_Entry_Flag = false;
   Sell_Entry_Flag = false;

}












/*------------------------------------------------------
関数名   DatePrint()
内容     パラメーターをプリントで表示する関数

引数     init_or_deinit:   initかdeinitか
         
戻り値   なし



-------------------------------------------------------*/
int DatePrint(string init_or_deinit)
{

   static int Start_GetTickCount;
   
   int End_GetTickCount;
   string End_GetTickCount_TimeStr;
   
   long trade_mode = NULL;
   
   double onelot_margin = NULL;
      
   MqlTick tick;
   
 

   if( init_or_deinit == "init" )
   {
      Start_GetTickCount = (int)GetTickCount();
      
      Print("--------□ ",MQLInfoString(MQL_PROGRAM_NAME)," □--------");
      Print(" ");
      Print("-------- ","copyright [OrderSystem]"," --------");
      Print("-------- ","link [http://www.fxordersystem.com]"," --------");
      Print(" ");
   
      Print("-------- Start Setup --------");
      Print(" ");
   
      Print("Start ServerTime = ",TimeToString(TimeCurrent()));               //サーバータイム
      Print("Start LocalTime = ",TimeToString(TimeLocal()));                  //ローカルタイム
      Print("AccountCompany = ",AccountInfoString(ACCOUNT_COMPANY));                         //ブローカー
      Print("AccountServer = ",AccountInfoString(ACCOUNT_SERVER));                           //サーバー
      
      trade_mode = AccountInfoInteger(ACCOUNT_TRADE_MODE);
      
      //--- 口座の種類を検出する 
     if(trade_mode == ACCOUNT_TRADE_MODE_DEMO) Print("ACCOUNT_TRADE_MODE = demo account"); 
     else if(trade_mode == ACCOUNT_TRADE_MODE_DEMO) Print("ACCOUNT_TRADE_MODE = competition account"); 
     else Print("ACCOUNT_TRADE_MODE = real account");  
      
      Print("IsDllsAllowed = ",TerminalInfoInteger(TERMINAL_DLLS_ALLOWED));                           //DLLがOKかどうか
      Print("IsTradeAllowed = ",MQLInfoInteger(MQL_TRADE_ALLOWED));                         //自動売買がOKかどうか
      Print("IsLibrariesAllowed = ",MQLInfoInteger(MQL_DLLS_ALLOWED));                 //Allow live tradingにチェックを付けているかどうか
      Print("IsExpertEnabled = ",AccountInfoInteger(ACCOUNT_TRADE_EXPERT));                      //Expert Advisorsが有効かどうか
      Print("IsTesting = ",MQLInfoInteger(MQL_TESTER));                                   //バックテストかどうか
      Print("IsVisualMode = ",MQLInfoInteger(MQL_VISUAL_MODE));                             //VisualModeかどうか
      Print("IsOptimization = ",MQLInfoInteger(MQL_OPTIMIZATION));                         //Optimization(最適化)にチェックが入っているかどうか
      Print("Symbol = ",Symbol());                                         //通貨ペア
      Print("Period = ",Period());                                         //時間足
      Print("Digits = ",Digits());                                           //レートの小数点の桁数
      Print("Spread = ",SymbolInfoInteger(Symbol(),SYMBOL_SPREAD));               //スプレッド
      Print("STOPLEVEL = ",SymbolInfoInteger(Symbol(),SYMBOL_TRADE_STOPS_LEVEL));         //指値最小Pips
      Print("Freezelevel = ",SymbolInfoInteger(Symbol(),SYMBOL_TRADE_FREEZE_LEVEL));     //フリーズレベル
      Print("AccountBalance() = "+(string)AccountInfoDouble(ACCOUNT_BALANCE));                                         //口座残高
      Print("AccountLeverage() = "+(string)AccountInfoInteger(ACCOUNT_LEVERAGE));                                       //口座の最大レバレッジ
      Print("MODE_LOTSIZE = "+(string)SymbolInfoDouble(Symbol(),SYMBOL_TRADE_CONTRACT_SIZE));   //1 ロットのサイズ（通貨数）
      Print("MODE_MINLOT = "+(string)SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN));     //最小ロット数
      Print("MODE_LOTSTEP = "+(string)SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_STEP));   //ロットの単位
      Print("MODE_MAXLOT = "+(string)SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX));     //最大ロット数
      
      
      SymbolInfoTick(_Symbol, tick);
      
      if( OrderCalcMargin( ORDER_TYPE_BUY,Symbol(),1,tick.ask,onelot_margin))
      {
         Print("MODE_MARGINREQUIRED = "+(string)onelot_margin);//１ロットあたりの余剰証拠金
      }
      
      
      Print(" ");
      Print("-------- Parameter --------");
      Print(" ");
   
      Print("Slippage = ",Slippage);
      Print("lots = ",Lots);
      Print("TakeProfit = ",TakeProfit);
      Print("StopLoss = ",StopLoss);
      
      Print("Long_Entry_Heiken_Ashi_Bars = ",Long_Entry_Heiken_Ashi_Bars);
      Print("Short_Entry_Heiken_Ashi_Bars = ",Short_Entry_Heiken_Ashi_Bars);
      Print("Long_Close_Heiken_Ashi_Bars = ",Long_Close_Heiken_Ashi_Bars);
      Print("Short_Close_Heiken_Ashi_Bars = ",Short_Close_Heiken_Ashi_Bars);
      
         
      Print(" ");
      Print("----------------------------------------------------");

   }
   else if( init_or_deinit == "deinit" )
   {
   
      End_GetTickCount = ((int)GetTickCount() - Start_GetTickCount)/1000;
      End_GetTickCount_TimeStr = TimeToString(End_GetTickCount,TIME_DATE|TIME_SECONDS);

      End_GetTickCount_TimeStr = StringSubstr( End_GetTickCount_TimeStr,5,0);

   
   
      Print("-------- ",MQLInfoString(MQL_PROGRAM_NAME)," --------");
      Print(" ");
      Print("-------- End Setup --------");
      Print(" ");
      
      Print("End ServerTime = ",TimeToString(TimeCurrent()));   //サーバータイム
      Print("End LocalTime = ",TimeToString(TimeLocal()));      //ローカルタイム
      Print("EA起動時間 = ",End_GetTickCount_TimeStr);      //起動時間
      
      
      Print(" ");
      Print("----------------------------------------------------");
   
   }

      
 
   return(0);

}







/*------------------------------------------------------
関数名   Time_Function
内容     MT4のTime[]と同じもの

引数   int shift  シフト

戻り値　 datetime return_time

-------------------------------------------------------*/
datetime Time_Function(int shift)
{
   datetime return_time = NULL;
   
   datetime Time[];

   ArraySetAsSeries(Time,true);

   CopyTime(_Symbol,_Period,shift,1,Time);

   return_time = Time[0];
   
   return(return_time);

}








//インジケーターのデータのコピー
void Indicators_Val_Copy()
{
//---
   //データを配列にコピー
   CopyBuffer(h_heiken_ashi,0,0,Heiken_Ashi_Max_Bars+2,Heiken_Ashi_Open_Val);
   CopyBuffer(h_heiken_ashi,3,0,Heiken_Ashi_Max_Bars+2,Heiken_Ashi_Close_Val);
   
}









/*------------------------------------------------------
関数名   AccountSpecification
内容     アカウント指定機能を付ける関数

         
戻り値   false:アカウント不一致    true:アカウント一致

-------------------------------------------------------*/
bool AccountSpecification()
{

 

   //もしアカウントが同一だったら
   if( AccountInfoInteger(ACCOUNT_LOGIN) == Account_Number || Account_Number == 0 )
   {
      //アカウント一致
      return(true);
   }

   //アカウント不一致   
   return(false);


}






//+------------------------------------------------------------------+

