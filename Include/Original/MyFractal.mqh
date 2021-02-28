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
enum IndexType {
   SLower = 0,
   SUpper = 1,
   MLower = 2,
   MUpper = 3,
   LLower = 4,
   LUpper = 5
};
class MyFractal: public CiFractals {

 public:
   CArrayInt SUpperIndex, SLowerIndex, MUpperIndex, MLowerIndex, LUpperIndex, LLowerIndex;
   int UIndex, LIndex;

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
         if(FractalMaximum(SUpperIndex, STotal - 3) == STotal - 2)
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
         if(FractalMinimum(SLowerIndex, STotal - 3) == STotal - 2)
            MLowerIndex.Add(SLowerIndex.At(STotal - 2));
         myChart.HLine(Lower(MLowerIndex.At(0)), 0, "LMiddle", clrAqua);
         myChart.HLine(Lower(SLowerIndex.At(0)), 0, "LShort", clrAntiqueWhite);
      }
   }

   void SearchLUpperIndex() {
      SearchMUpperIndex(3);
      while(LUpperIndex.Total() < 1) {
         int MTotal = MUpperIndex.Total();
         SearchMUpperIndex(MTotal + 1);
         if(FractalMaximum(MUpperIndex, MTotal - 3) == MTotal - 2)
            LUpperIndex.Add(MUpperIndex.At(MTotal - 2));
         myChart.HLine(Upper(LUpperIndex.At(0)), 0, "ULong", clrRed);
         myChart.HLine(Upper(MUpperIndex.At(0)), 0, "UMiddle", clrAqua);
         myChart.HLine(Upper(SUpperIndex.At(0)), 0, "UShort", clrAntiqueWhite);
      }
   }

   void SearchLLowerIndex() {
      SearchMLowerIndex(3);
      while(LLowerIndex.Total() < 1) {
         int MTotal = MLowerIndex.Total();
         SearchMLowerIndex(MTotal + 1);
         if(FractalMinimum(MLowerIndex, MTotal - 3) == MTotal - 2)
            LLowerIndex.Add(MLowerIndex.At(MTotal - 2));
         myChart.HLine(Lower(LLowerIndex.At(0)), 0, "LLong", clrRed);
         myChart.HLine(Lower(MLowerIndex.At(0)), 0, "LMiddle", clrAqua);
         myChart.HLine(Lower(SLowerIndex.At(0)), 0, "LShort", clrAntiqueWhite);
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

   int FractalMaximum(CArrayInt &index, int start) {
      int i;
      int Max = 0;
      for(i = start + 1; i < start + 3; i++) {
         if(Upper(index.At(i - 1)) < Upper(index.At(i))) Max = i;
      }
      return Max;
   }

   int FractalMinimum(CArrayInt &index, int start) {
      int i;
      int Min = 0;
      for(i = start + 1; i < start + 3; i++) {
         if(Lower(index.At(i - 1)) > Lower(index.At(i))) Min = i;
      }
      return Min;
   }

   double fractal(IndexType type, int index) {
      CArrayDouble Index;
      if(type == SLower) {
         Index = SLowerIndex;
      } else if(type == SUpper) {
         Index = SUpperIndex;
      } else if(type == MLower) {
         Index = MLowerIndex;
      } else if(type == MUpper) {
         Index = MUpperIndex;
      } else if(type == LLower) {
         Index = LLowerIndex;
      } else if(type == LUpper) {
         Index = LUpperIndex;
      }
      return Index.At(index);
   }
};
//+------------------------------------------------------------------+
