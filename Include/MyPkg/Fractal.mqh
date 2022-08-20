//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

#include <Indicators\BillWilliams.mqh>
#include <Original\MyCalculate.mqh>
#include <Original\MyCHart.mqh>

enum IndexType {
   SLower = 0,
   SUpper = 1,
   MLower = 2,
   MUpper = 3,
   LLower = 4,
   LUpper = 5
};
enum Span {
   Short,
   Middle,
   Long
};
enum Target {
   Up,
   Low
};

class Fractal: public CiFractals {

 public:
   CArrayInt SUpperIndex, SLowerIndex, MUpperIndex, MLowerIndex, LUpperIndex, LLowerIndex;
   int UIndex, LIndex;

   void Refresh() {
      CiFractals::Refresh();
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
   
   void SearchShort(int total = 1){
      SearchSUpperIndex(total);
      SearchSLowerIndex(total);
   }

   void SearchMiddle(int total = 1) {
      SearchMUpperIndex(total);
      SearchMLowerIndex(total);
   }

   void SearchMUpperIndex(int total = 1) {
      SearchSUpperIndex(3);
      for(int STotal = SUpperIndex.Total(); STotal < 35; STotal++) {
         if(MUpperIndex.Total() == total) break;
         SearchSUpperIndex(STotal + 1);
         if(FractalMaximum(SUpperIndex, STotal - 3, 3) == STotal - 2 && fractal(Short, Up, STotal - 2) > fractal(Short, Up, 0))
            MUpperIndex.Add(SUpperIndex.At(STotal - 2));
      }
      myChart.HLine(fractal(Middle, Up, 0), 0, "MiddleUpper", clrAqua);
      myChart.HLine(fractal(Short, Up, 0), 0, "ShortUpper", clrAntiqueWhite);
   }

   void SearchMLowerIndex(int total = 1) {
      SearchSLowerIndex(3);
      for(int STotal = SLowerIndex.Total(); STotal < 35; STotal++) {
         if(MLowerIndex.Total() == total) break;
         SearchSLowerIndex(STotal + 1);
         if(FractalMinimum(SLowerIndex, STotal - 3, 3) == STotal - 2 && fractal(Short, Low, STotal - 2) < fractal(Short, Low, 0))
            MLowerIndex.Add(SLowerIndex.At(STotal - 2));
      }
      myChart.HLine(fractal(Middle, Low, 0), 0, "MiddleLower", clrAqua);
      myChart.HLine(fractal(Short, Low, 0), 0, "ShortLower", clrAntiqueWhite);
   }

   void SearchLUpperIndex() {
      SearchMUpperIndex(3);
      while(LUpperIndex.Total() < 1) {
         int MTotal = MUpperIndex.Total();
         SearchMUpperIndex(MTotal + 1);
         if(FractalMaximum(MUpperIndex, MTotal - 3, 3) == MTotal - 2 && MUpperIndex.At(MTotal - 2) > MUpperIndex.At(0))
            LUpperIndex.Add(MUpperIndex.At(MTotal - 2));
      }
      myChart.HLine(fractal(Long, Up, 0), 0, "LongUpper", clrRed);
      myChart.HLine(fractal(Middle, Up, 0), 0, "MiddleUpper", clrAqua);
      myChart.HLine(fractal(Short, Up, 0), 0, "ShortUpper", clrAntiqueWhite);
   }

   void SearchLLowerIndex() {
      SearchMLowerIndex(3);
      while(LLowerIndex.Total() < 1) {
         int MTotal = MLowerIndex.Total();
         SearchMLowerIndex(MTotal + 1);
         if(FractalMinimum(MLowerIndex, MTotal - 3, 3) == MTotal - 2 && MLowerIndex.At(MTotal - 2) > MLowerIndex.At(0))
            LLowerIndex.Add(MLowerIndex.At(MTotal - 2));
      }
      //myChart.HLine(fractal(Long, Low, 0), 0, "LongLower", clrRed);
      //myChart.HLine(fractal(Middle, Low, 0), 0, "MiddleLower", clrAqua);
      //myChart.HLine(fractal(Short, Low, 0), 0, "ShortLower", clrAntiqueWhite);
   }

   void SearchLong() {
      SearchLLowerIndex();
      SearchLUpperIndex();
   }

   bool isLMLinedCorrectly() {
      if(fractal(Long, Up, 0) > fractal(Middle, Up, 0) && fractal(Long, Low, 0) < fractal(Middle, Low, 0))
         return true;
      return false;
   }

   bool isMSLinedCorrectly() {
      if(fractal(Middle, Up, 0) > fractal(Short, Up, 0) && fractal(Middle, Low, 0) < fractal(Short, Low, 0))
         return true;
      return false;
   }

   int FractalMaximum(CArrayInt &index, int start, int count) {
      int i;
      int Max = 0;
      for(i = start + 1; i < start + count; i++) {
         if(Upper(index.At(i - 1)) < Upper(index.At(i))) Max = i;
      }
      return Max;
   }

   int FractalMinimum(CArrayInt &index, int start, int count) {
      int i;
      int Min = 0;
      for(i = start + 1; i < start + count; i++) {
         if(Lower(index.At(i - 1)) > Lower(index.At(i))) Min = i;
      }
      return Min;
   }

   bool isRecentShortFractal(Target tar) {
      if(tar == Up) {
         if(Upper(2) == fractal(Short, tar)) return true;
      } else if(tar == Low) {
         if(Lower(2) == fractal(Short, tar)) return true;
      }
      return false;
   }

   bool isRecentMiddleFractal(Target tar) {
      if(fractal(Middle, tar, 0) == fractal(Short, tar, 1)) {
         if(isRecentShortFractal(tar))
            return true;
      }
      return false;
   }

   double fractal(Span span, Target tar, int index = 0) {
      CArrayInt Index;
      if(tar == Up) {
         if(span == Short) Index = SUpperIndex;
         else if(span == Middle) Index = MUpperIndex;
         else if(span == Long) Index = LUpperIndex;
         return Upper(Index.At(index));
      } else {
         if(span == Short) Index = SLowerIndex;
         else if(span == Middle) Index = MLowerIndex;
         else if(span == Long) Index = LLowerIndex;
         return Lower(Index.At(index));
      }
   }

 private:
   MyChart myChart;
};
//+------------------------------------------------------------------+
