//+------------------------------------------------------------------+
//|                                                 ZZ_FF_v4.mq4   |
//|                                                 George Tischenko |
//|                    Zig-Zag & Fractal Filter                      |
//+------------------------------------------------------------------+
/*
������ ������� ����������� ������������ � ������� ������� iHighest / iLowest
���������� ���������� �������� ������������ � ������� ������������ �������
��������� ������������ ���������, ������������ �� ��������� ������� ����������
*/
#property copyright "George Tischenko"

#property indicator_chart_window
#property indicator_buffers 2
#property indicator_color1 DodgerBlue
#property indicator_color2 DodgerBlue

extern int ExtPeriod=10;  //���������� ����� ��� ������� �����������
extern int MinAmp=10;     //����������� ���������� ���� ����� ��������� ����� � �������� (����� �� ��������������)

int TimeFirstExtBar,lastUPbar,lastDNbar,TimeOpen; //����� �������� �������� ����;
double MP,lastUP,lastDN;
double UP[],DN[];
bool downloadhistory=false;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
  TimeFirstExtBar=0;
  TimeOpen=0;
  MP=MinAmp*Point;
  lastUP=0; lastDN=0;
//---- indicators
  IndicatorDigits(Digits);
  IndicatorBuffers(6); 
  
  SetIndexBuffer(0,UP);
  SetIndexStyle(0,DRAW_ZIGZAG,STYLE_SOLID,3);
  
  SetIndexBuffer(1,DN);
  SetIndexStyle(1,DRAW_ZIGZAG);
//----
  SetIndexLabel(0,"UP");
  SetIndexLabel(1,"DN");
  return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
//----
//----
  return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
  {
  int BarsForRecalculation,i;
  int counted_bars=IndicatorCounted();
  if(Bars-counted_bars>2) 
    {
    BarsForRecalculation=Bars-ExtPeriod-1;
    if(downloadhistory) //������� ���������
      {
      ArrayInitialize(UP,EMPTY_VALUE);
      ArrayInitialize(DN,EMPTY_VALUE);
      }
    else downloadhistory=true;
    }
  else BarsForRecalculation=Bars-counted_bars;
  if(BarsForRecalculation>0) TimeOpen=Time[Bars-counted_bars]; //�������� ��� ������ ��� �������� ��-4 � ���������
/*
� ����� � ���, ��� ��������� �� ����������� �������� ������� ��������� ������������ 2 ����� ������
(��������� ��. ������� Fractal) - �������������� ������� �� 3 ���� ����� ��������� �������������� 
������ ��� �������� �������� �������� ����: [3]-2-1-0 ������� ������ ����� ����������� ������ ��� 
�������� ������ ����. ������ ���� ��� ����������� ����� ����� ������ �� ������������.
*/
  if(TimeOpen<Time[0]) 
    {  
//======== �������� ����
    while(BarsForRecalculation>1)
     {
     i=BarsForRecalculation+1; lastUP=0; lastDN=0; lastUPbar=i; lastDNbar=i;
     int LET=LastEType(); //����� ���������� ����������
     
//---- ���������� ������� ���������� �� ��������� ������:       
     double H=High[iHighest(NULL,0,MODE_HIGH,ExtPeriod,i)];
     double L=Low[iLowest(NULL,0,MODE_LOW,ExtPeriod,i)];
            
//---- ����������, ������� �� �� ���� [i] �������� ����������� ��� ������������ ���: 
     double Fup=Fractal(1,i); //MODE_UPPER 
     double Fdn=Fractal(2,i); //MODE_LOWER
     
//---- �������������� �������� � ���������� ����������� ����������� ����� �����������: 

     switch(Comb(i,H,L,Fup,Fdn))
       {
//---- �� ��������� ���� ������������� ��� (Comb)      
       case 1 :
         {
         switch(LET)
           {
           case 1 : //���������� ��������� ���� ���
             {//�������� �������:
             if(NormalizeDouble(Fup-lastUP,Digits)>0) {UP[lastUPbar]=EMPTY_VALUE; UP[i]=Fup;}
             break;
             }
           case -1 : if(NormalizeDouble(Fup-lastDN-MP,Digits)>0) UP[i]=Fup; break; //���������� ��������� - �������
           default : UP[i]=Fup; TimeFirstExtBar=iTime(NULL,0,i); //0 - ������ ��� ������ ������� 
           }
         break;
         }
          
//---- �� ��������� ���� ������������� �������  (Comb)          
       case -1 :
         {
         switch(LET)
          {
          case 1 : if(NormalizeDouble(lastUP-Fdn-MP,Digits)>0) DN[i]=Fdn; break; //���������� ��������� - ���
          case -1 : //���������� ��������� ���� �������
            {
            if(NormalizeDouble(lastDN-Fdn,Digits)>0) {DN[lastDNbar]=EMPTY_VALUE; DN[i]=Fdn;}
            break;
            }
          default : DN[i]=Fdn; TimeFirstExtBar=iTime(NULL,0,i); //0 - ������ ��� ������ ������� 
          }
        break;
        }
       
//---- �� ��������� ���� ������������� ��� � ������������� ������� (Comb)        
      case 2 : //���������������� ������� ������������� LOW ����� HIGH (����� ���)
        {
        switch(LET)
          {
          case 1 : //���������� ��������� - ���
            {
            if(NormalizeDouble(Fup-Fdn-MP,Digits)>0)
              {
              if(NormalizeDouble(lastUP-Fdn-MP,Digits)>0) {UP[i]=Fup; DN[i]=Fdn;}
              else 
                {
                if(NormalizeDouble(Fup-lastUP,Digits)>0) {UP[lastUPbar]=EMPTY_VALUE; UP[i]=Fup;}
                }
              }
            else
              {
              if(NormalizeDouble(lastUP-Fdn-MP,Digits)>0) DN[i]=Fdn;
              else
                {
                if(NormalizeDouble(Fup-lastUP,Digits)>0) {UP[lastUPbar]=EMPTY_VALUE; UP[i]=Fup;}
                }
              }
            break;
            }
          case -1 : //���������� ��������� - �������
            {
            if(NormalizeDouble(Fup-Fdn-MP,Digits)>0)
              {
              UP[i]=Fup;
              if(NormalizeDouble(lastDN-Fdn,Digits)>0 && iTime(NULL,0,lastDNbar)>TimeFirstExtBar) 
                {DN[lastDNbar]=EMPTY_VALUE; DN[i]=Fdn;}
              }
            else
              {
              if(NormalizeDouble(Fup-lastDN-MP,Digits)>0) UP[i]=Fup;
              else
                {
                if(NormalizeDouble(lastDN-Fdn,Digits)>0) {DN[lastDNbar]=EMPTY_VALUE; DN[i]=Fdn;}
                }
              }
            }
          } //switch LET
        break;
        }// case 2
      
      case -2 : //���������������� ������� ������������� HIGH ����� LOW (�������� ���)
        {
        switch(LET)
          {
          case 1 : //���������� ��������� - ���
            {
            if(NormalizeDouble(Fup-Fdn-MP,Digits)>0)
              {
              DN[i]=Fdn;
              if(NormalizeDouble(Fup-lastUP,Digits)>0 && iTime(NULL,0,lastUPbar)>TimeFirstExtBar) 
                {UP[lastUPbar]=EMPTY_VALUE; UP[i]=Fup;}
              }
            else
              {
              if(NormalizeDouble(lastUP-Fdn-MP,Digits)>0) DN[i]=Fdn;
              else
                {
                if(NormalizeDouble(Fup-lastUP,Digits)>0) {UP[lastUPbar]=EMPTY_VALUE; UP[i]=Fup;}
                }
              }
            break;
            }
          case -1 : //���������� ��������� - �������
            {
            if(NormalizeDouble(Fup-Fdn-MP,Digits)>0)
              {
              if(NormalizeDouble(Fup-lastDN-MP,Digits)>0) {UP[i]=Fup; DN[i]=Fdn;}
              else
                {
                if(NormalizeDouble(lastDN-Fdn,Digits)>0) {DN[lastDNbar]=EMPTY_VALUE; DN[i]=Fdn;}
                }
              }
            else
              {
              if(NormalizeDouble(Fup-lastDN-MP,Digits)>0) UP[i]=Fup;
              else
                {
                if(NormalizeDouble(Fdn-lastDN,Digits)>0) {DN[lastDNbar]=EMPTY_VALUE; DN[i]=Fdn;}
                }
              }
            }
          } //switch LET
        }// case -2 
      }
//----  
     BarsForRecalculation--;    
     } 
//========
    TimeOpen=Time[0];
    }
//----
  return(0);
  }
//+------------------------------------------------------------------+
//| ������� ����������� ���������                                    |
//+------------------------------------------------------------------+  
double Fractal(int mode, int i) 
  {
//----
  bool fr=true;
  int a,b,count;
  double res;
  
  switch(mode)
    {
    
    case 1 : //����� ������� ���������
//������ �� �������� ������ ���� 2 ���� � ����� ������� �����������
//����� �� �������� ����� ���� ������ �����, ������� �������� 2 ���� � ����� ������� ����������� 
//�������� ������ ���� �� ������ �� ������ ��������� �������� ������������ ����    
      {
      for(b=i-1;b>i-3;b--) 
        {
        if(High[i]<=High[b]) {fr=false; break;}
        }
      a=i+1; 
      while(count<2)
        {
        if(High[i]<High[a]) {fr=false; break;}
        else
          {
          if(High[i]>High[a]) count++;
          else count=0;
          }
        a++;
        }
      if(fr==true) res=High[i];
      break;
      }
      
    case 2 : //����� ������ ���������
//������ �� �������� ������ ���� 2 ���� � ����� �������� ����������
//����� �� �������� ����� ���� ������ �����, ������� �������� 2 ���� � ����� �������� ���������� 
//������� ������ ���� �� ������ �� ������ ���� ���� �������� ������������ ���� 
      {
      for(b=i-1;b>i-3;b--) 
        {
        if(Low[i]>=Low[b]) {fr=false; break;}
        }
      a=i+1; 
      while(count<2)
        {
        if(Low[i]>Low[a]) {fr=false; break;}
        else
          {
          if(Low[i]<Low[a]) count++;
          else count=0;
          }
        a++;
        }
      if(fr==true) res=Low[i];
      }
    }
//----
  return(res);  
  } 
//+------------------------------------------------------------------+
//| ������� ����������� ���������� ����������                        |
//+------------------------------------------------------------------+  
int LastEType()
  {
//----
  int m,n,res;
  m=0; n=0;
  while(UP[lastUPbar]==EMPTY_VALUE) {if(lastUPbar>Bars-ExtPeriod) break; lastUPbar++;} 
  lastUP=UP[lastUPbar]; //�������� ����� ��������� ���
  while(DN[lastDNbar]==EMPTY_VALUE) {if(lastDNbar>Bars-ExtPeriod) break; lastDNbar++;} 
  lastDN=DN[lastDNbar]; //�������� ����� ��������� �������
  if(lastUPbar<lastDNbar) res=1;
  else
    {
    if(lastUPbar>lastDNbar) res=-1;
    else //lastUPbar==lastDNbar ���� ������, ����� ��������� ��������� ��� ���������:
      {
      m=lastUPbar; n=m;
      while(m==n)
        {
        m++; n++;
        while(UP[m]==EMPTY_VALUE) {if(m>Bars-ExtPeriod) break; m++;} //�������� ����� ��������� ���
        while(DN[n]==EMPTY_VALUE) {if(n>Bars-ExtPeriod) break; n++;} //�������� ����� ��������� �������
        if(MathMax(m,n)>Bars-ExtPeriod) break;
        }
      if(m<n) res=1;       //������� ������ - ���
      else if(m>n) res=-1; //������� ������ - �������
      }
    }
//----    
  return(res); //���� res==0 - ������ ��� ������ ������� ��� � ����� ������ ������������ ������� ��� � 2 ������������
  }
//+------------------------------------------------------------------+
//| ������� ������� ������� ��������                                 |
//+------------------------------------------------------------------+ 
int Comb(int i, double H, double L, double Fup, double Fdn)
  {
//----
  if(Fup==H && (Fdn==0 || (Fdn>0 && Fdn>L))) return(1);  //�� ��������� ���� ������������� ���
  if(Fdn==L && (Fup==0 || (Fup>0 && Fup<H))) return(-1); //�� ��������� ���� ������������� �������
  if(Fdn==L && Fup==H)                                   //�� ��������� ���� ������������� ��� � ������������� ������� 
    {
    switch(GetOrderFormationBarHighLow(i))
      {//���������������� ������� ������������� LOW ����� HIGH (����� ���)
      case -1 : return(2); break;
      //���������������� ������� ������������� HIGH ����� LOW (�������� ���)
      case 1 : return(-2); 
      }
    }
//----  
  return(0);                                             //�� ��������� ���� �����...
  }
//+------------------------------------------------------------------+
//| ������� ���������� ������� ������������ High Low ��� ����        |
//|  1: ������� High, ����� Low                                      |
//| -1: ������� Low, ����� High                                      |
//|  0: High = Low                                                   |
//+------------------------------------------------------------------+ 
int GetOrderFormationBarHighLow(int Bar)
  {
//---- ��� ������ ������� ���������� ������ �� Open / Close
  int res = 0;
  if(High[Bar]==Low[Bar]) return(res);
  if(Close[Bar]>Open[Bar]) res=-1;
  if(Close[Bar]<Open[Bar]) res=1;
   
  if(res==0) // ����� Close = Open
    {
    double a1=High[Bar]-Close[Bar];
    double a2=Close[Bar]-Low[Bar];
    if(a1>a2) res=-1;
    if(a1<a2) res=1;
    if(res==0) res=1; // ����� � ��� �����  - ����� ��� �������! � �����! - �������!
    }
//----
  return(res);
  } 
//+------------------------------------------------------------------+