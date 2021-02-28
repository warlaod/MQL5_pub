//+------------------------------------------------------------------+
//|                                                    MyFractal.mqh |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
// #define MacrosHello   "Hello, world!"
// #define MacrosYear    2010
//+------------------------------------------------------------------+
//| DLL imports                                                      |
//+------------------------------------------------------------------+
// #import "user32.dll"
//   int      SendMessageA(int hWnd,int Msg,int wParam,int lParam);
// #import "my_expert.dll"
//   int      ExpertRecalculate(int wParam,int lParam);
// #import
//+------------------------------------------------------------------+
//| EX5 imports                                                      |
//+------------------------------------------------------------------+
// #import "stdlib.ex5"
//   string ErrorDescription(int error_code);
// #import
//+------------------------------------------------------------------+
#include <Indicators\BillWilliams.mqh>
#include <Original\MyCalculate.mqh>
#include <Original\MyCHart.mqh>

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MyChart myChart;
class MyFractal: public CiFractals {
 public:
   int MHighestIndex;
   int KeySize;
   CArrayInt SUpperIndex, SLowerIndex, MUpperIndex, MLowerIndex, LUpperIndex, LLowerIndex;
   int UIndex, LIndex;

   void MyFractal(int KeySize) {
      this.KeySize = KeySize;
   }

   void myRefresh() {
      Refresh();
      UIndex = 1;
      LIndex = 1;
      SUpperIndex.Clear();
      SLowerIndex.Clear();
      MUpperIndex.Clear();
      MLowerIndex.Clear();
      LUpperIndex.Clear();
      LLowerIndex.Clear();
   }

   void SearchSUpperIndex(int total) {
      while(SUpperIndex.Total() < total) {
         if(Upper(UIndex) != EMPTY_VALUE)
            SUpperIndex.Add(UIndex);
         UIndex++;
      }
   }
   void SearchSLowerIndex(int total) {
      while(SLowerIndex.Total() < total) {
         if(Lower(LIndex) != EMPTY_VALUE)
            SLowerIndex.Add(LIndex);
         LIndex++;
      }
   }

   void SearchMiddle(int total = 1) {
      SearchMUpperIndex(total);
      SearchMLowerIndex(total);
   }

   void SearchMUpperIndex(int total = 1) {
      SearchSUpperIndex(3);
      while(MUpperIndex.Total() < total) {
         int STotal = SUpperIndex.Total();
         SearchSUpperIndex(STotal + 1);
         if(FractalMaximum(SUpperIndex,STotal - 3) == STotal - 2)
            MUpperIndex.Add(SUpperIndex.At(STotal - 2));
         myChart.HLine(Upper(MUpperIndex.At(0)), 0, "UMiddle", clrAqua);
         myChart.HLine(Upper(SUpperIndex.At(0)), 0, "UShort", clrAntiqueWhite);
      }
   }

   void SearchMLowerIndex(int total = 1) {
      SearchSLowerIndex(3);
      while(MLowerIndex.Total() < total) {
         int STotal = SLowerIndex.Total();
         SearchSLowerIndex(STotal + 1);
         if(SLowerIndex.Minimum(STotal - 3, 3) == STotal - 2)
            MLowerIndex.Add(SLowerIndex.At(STotal - 2));
         myChart.HLine(MLowerIndex.At(0), 0, "LMiddle", clrAqua);
         myChart.HLine(SLowerIndex.At(0), 0, "LShort", clrAntiqueWhite);
      }
   }

   void SearchLUpperIndex() {
      SearchMUpperIndex(3);
      while(LUpperIndex.Total() < 1) {
         int MTotal = MUpperIndex.Total();
         SearchMUpperIndex(MTotal + 1);
         if(MUpperIndex.Maximum(MTotal - 3, 3) == MTotal - 2)
            LUpperIndex.Add(MUpperIndex.At(MTotal - 2));
         myChart.HLine(LUpperIndex.At(0), 0, "ULong", clrRed);
         myChart.HLine(MUpperIndex.At(0), 0, "UMiddle", clrAqua);
         myChart.HLine(SUpperIndex.At(0), 0, "UShort", clrAntiqueWhite);
      }
   }

   void SearchLLowerIndex() {
      SearchMLowerIndex(3);
      while(LLowerIndex.Total() < 1) {
         int MTotal = MLowerIndex.Total();
         SearchMLowerIndex(MTotal + 1);
         if(MLowerIndex.Minimum(MTotal - 3, 3) == MTotal - 2)
            LLowerIndex.Add(MLowerIndex.At(MTotal - 2));
         myChart.HLine(LLowerIndex.At(0), 0, "LLong", clrRed);
         myChart.HLine(MLowerIndex.At(0), 0, "LMiddle", clrAqua);
         myChart.HLine(SLowerIndex.At(0), 0, "LShort", clrAntiqueWhite);
      }
   }

   void SearchLong() {
      SearchLLowerIndex();
      SearchLUpperIndex();
   }

   bool isLMLinedCorrectly() {
      if(LUpperIndex.At(0) > MUpperIndex.At(0) && LLowerIndex.At(0) < MLowerIndex.At(0))
         return true;
      return false;
   }

   bool isMSLinedCorrectly() {
      if(MUpperIndex.At(0) > SUpperIndex.At(0) && MLowerIndex.At(0) < SLowerIndex.At(0))
         return true;
      return false;
   }

   bool isRecentFractal(bool isUpper, double Val) {
      if(isUpper) {
         if(Upper(2) == Val)
            return true;
      } else {
         if(Lower(2) == Val)
            return true;
      }
      return false;
   }
   
   int FractalMaximum(CArrayInt &index, int start){
     int i;
     int Max = 0;
     for(i=start+1;i<start+3;i++)
       {
        if(Upper(index.At(i-1)) < Upper(index.At(i))) Max = i;
       }
       return Max;
   }
   
   int FractalMinimum(CArrayInt &index, int start){
     int i;
     int Min = 0;
     for(i=start+1;i<start+3;i++)
       {
        if(Lower(index.At(i-1)) > Lower(index.At(i))) Min = i;
       }
       return Min;
   }
};
//+------------------------------------------------------------------+
