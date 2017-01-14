//+------------------------------------------------------------------+
//|                                                       MyAlgo.mq4 |
//|                                                    Tayyab Rashid |
//|                                             www.tayyabrashid.com |
//+------------------------------------------------------------------+
#property copyright "Tayyab Rashid"
#property link      "www.tayyabrashid.com"
#property version   "1.00"
#property strict

extern int TakeProfit=50;
extern int StopLoss=25;
extern double LotSize=0.01;

double pips;

extern bool UseBreakEven=True;
extern int MoveToBreakEven=50;
extern int PipsProfitLock=20;

extern bool UseTrailingStop=true;
extern int WhenToTrail=50;
extern int TrailAmount=30;
extern bool UseStoploss=true;
extern bool UseTakeProfit=true;
extern bool UsePosition=true;
extern bool UseRiskReward=true;
extern double reward_ratio=2;
extern int RiskPercent=1;
extern bool UseCandleClose=true;
extern int CloseAfterCandles=1;
extern bool TradeLong=true;
extern bool TradeShort=true;
extern int ShortMAPeriod=50;
extern int LongMAPeriod=100;




//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
  PipsFunction();
  Alert(pips);
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
void OnTick()
  {
  if(IsNewCandle())
     {
      if(TotalOpenOrders()<1)
         {
         EntrySignal();
         }
     }
     if(TotalOpenOrders()>0)
         {
         if(UseBreakEven)
            {
            BreakEven();
            }
         if(UseTrailingStop)
            {
            TrailingStop();
            }
          if(UseCandleClose)
            {
            CandleClose();
            }
         }
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|Our own New order send function                                   |
//+------------------------------------------------------------------+
void NewOrder()
{
int Result=OrderSend(Symbol(),OP_BUY,LotSize,Ask,3,NormalizeDouble(Ask-StopLoss*pips,4),NormalizeDouble(Ask+TakeProfit*pips,4),NULL,1234,0,clrNONE);
return;
}

bool IsNewCandle()
{
   static int BarsOnChart=0;
   if(Bars==BarsOnChart)
   return(false);
   BarsOnChart = Bars;
   return(true);
}

int TotalOpenOrders()
{
int Trades=0;
int Total=OrdersTotal();
   for(int i=Total;i>=0;i--)
      {
      if(OrderSelect(i-1,SELECT_BY_POS,MODE_TRADES))
         {
         if(OrderType()==OP_BUY || OrderType()==OP_SELL)
         Trades++;
         }
      }
      return(Trades);
}

void CloseAllOrders()//1.
{
int Total=OrdersTotal(); //2.
   for(int i=Total;i>=0;i--) //3. 
      {
      if(OrderSelect(i-1,SELECT_BY_POS,MODE_TRADES))//4.
         {
         if(OrderType()==OP_SELL)//5.
            {
            bool res1=OrderClose(OrderTicket(),OrderLots(),Ask,3,clrNONE);//6.
            }
         if(OrderType()==OP_BUY)//7.
            {
           bool res2= OrderClose(OrderTicket(),OrderLots(),Bid,3,clrNONE);//8. 
            }
         if(OrderType()==OP_BUYLIMIT || OrderType()==OP_BUYSTOP|| OrderType()==OP_SELLSTOP||OrderType()==OP_SELLLIMIT)//9. 
            {
          bool res3= OrderDelete(OrderTicket(),clrNONE);//10.
            }
         }
      }
return;
}

void PipsFunction()//1.
{
double ticksize=MarketInfo(Symbol(),MODE_TICKSIZE);//2.
    if (ticksize == 0.00001 || ticksize == 0.001)//3.    
    {
    pips = ticksize*10;//4.
    }
    else
    {
    pips = ticksize;//5.
    }
return;
}

void BreakEven()//1.
{
for(int i=OrdersTotal();i>0;i--)//2.
   {
   if(OrderSelect(i-1,SELECT_BY_POS,MODE_TRADES))//3.
   {
      if(OrderType()==OP_BUY)//4.
         {
         if(Bid-OrderOpenPrice()>MoveToBreakEven*pips)//5.
            {
            if(OrderOpenPrice()>OrderStopLoss())//6.
               {
             bool res1=OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()+PipsProfitLock*pips,OrderTakeProfit(),0,clrNONE);//7.
              Alert("Yes");
               }
            }
         }
      if(OrderType()==OP_SELL)
      
         {
         if(OrderOpenPrice()-Bid>MoveToBreakEven*pips)
            {
            if(OrderOpenPrice()<OrderStopLoss())
                  {
                  bool res1=OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()-PipsProfitLock*pips,OrderTakeProfit(),0,clrNONE);
                  }
            }
         }
       }
   }
}

void TrailingStop()//1.
{
   for(int i=OrdersTotal();i>0;i--)//2.
      {
      if(OrderSelect(i-1,SELECT_BY_POS,MODE_TRADES))//3.
         {
         if(OrderType()==OP_BUY)//4.
            {
            if(Bid-OrderOpenPrice()>WhenToTrail*pips)//5.
               {
               if(OrderStopLoss()<Bid-TrailAmount*pips)//6.
                  {
                  bool res1=OrderModify(OrderTicket(),OrderOpenPrice(),Bid-TrailAmount*pips,OrderTakeProfit(),0,clrNONE);//7.
                  }
                  
               }
            }
         if(OrderType()==OP_SELL)
            {
            if(OrderOpenPrice()-Bid>WhenToTrail*pips)
               {
               if(OrderStopLoss()>Bid+TrailAmount*pips)
                  {
                  bool res1=OrderModify(OrderTicket(),OrderOpenPrice(),Bid+TrailAmount*pips,OrderTakeProfit(),0,clrNONE);
                  }
                }
             } 
         }
      
      }
return;
}

void Trade(int Direction)//1.
{
double SL;//2.
double TP;//3.
double Equity=AccountEquity();//4
double RiskedAmount=Equity*RiskPercent*0.01;//5.
double Lots=0;//6.


   if(Direction==0)//.7
   {
   if(UseStoploss)//8.
         {
         SL=Bid-StopLoss*pips;
         }
         else
         {
         SL=0;
         }
      double PipsToBuyStoploss=StopLoss*pips;
      
      
      if(UseTakeProfit)//.9
         {
         if(UseRiskReward && UseStoploss)//10.
            {
            TP=(Bid-SL)*2+Bid;
            }
         else 
            {
            TP=Bid+TakeProfit*pips;
            }
         }
         else
         {
         TP=0;
         }
      if(UsePosition && UseStoploss)//.11
      {
       Lots=(RiskedAmount/(PipsToBuyStoploss/pips))/10;
      }
      else
      {
      Lots=LotSize;
      }
     int res=OrderSend(Symbol(),OP_BUY,Lots,Ask,3,NormalizeDouble(SL,4),NormalizeDouble(TP,4),NULL,0,0,clrNONE);//11.
     Alert(TP);
   }
   
   if(Direction==1)
   {
      if(UseStoploss)
         {
         SL=Ask+StopLoss*pips;
         }
         else
         {
         SL=0;
         }
      double PipsToSellStoploss=StopLoss*pips;
      
      
      if(UseTakeProfit)
         {
         if(UseRiskReward && UseStoploss)
            {
            TP=Ask-((SL-Ask)*2);
            }
         else 
            {
            TP=Ask-TakeProfit*pips;
            }
         }
         else
         {
         TP=0;
         }
      if(UsePosition && UseStoploss)
      {
       Lots=(RiskedAmount/(PipsToSellStoploss/pips))/10;
      }
      else
      {
      Lots=LotSize;
      }
    
     int res=OrderSend(Symbol(),OP_SELL,Lots,Bid,3,NormalizeDouble(SL,4),NormalizeDouble(TP,4),NULL,0,0,clrNONE);
   }
return;  
}

void CandleClose()//1
{
   int period=Period();//2.
   int period2=0;//3.
  
   
   switch(period)//4.
   {  case 1:period2=60;break;
      case 5:period2=300;break;
      case 15:period2=900;break;
      case 30:period2=1800;break;
      case 60:period2=3600;break;
      case 240:period2=14400;break;
      case 1440:period2=86400;break;
      case 10080:period2=604800;break;
      case 43200:period2=2592000;break;
      //default: Alert("Nothing"); 
   }
     
for(int i=OrdersTotal();i>0;i--)//5.
   {
   if(OrderSelect(i-1,SELECT_BY_POS,MODE_TRADES))//6.
      {
      if(TimeCurrent()-OrderOpenTime()>period2*CloseAfterCandles)//7.
         {
         CloseAllOrders();//8.
         }
      }
   }
   return;
}

void EntrySignal()//0
{
double ShortMaCurrent=iMA(Symbol(),PERIOD_CURRENT,ShortMAPeriod,0,MODE_SMA,PRICE_CLOSE,1);//1.
double LongMaCurrent=iMA(Symbol(),PERIOD_CURRENT,LongMAPeriod,0,MODE_SMA,PRICE_CLOSE,1);
double ShortMaPrevious=iMA(Symbol(),PERIOD_CURRENT,ShortMAPeriod,0,MODE_SMA,PRICE_CLOSE,2);
double LongMaPrevious=iMA(Symbol(),PERIOD_CURRENT,LongMAPeriod,0,MODE_SMA,PRICE_CLOSE,2);

   if(TradeLong)//.2
   {
      if(ShortMaPrevious<LongMaPrevious && ShortMaCurrent>LongMaCurrent)//3.
         {
         Trade(0);//.4
         }
   }
   if(TradeShort)
   {
      if(ShortMaPrevious>LongMaPrevious && ShortMaCurrent<LongMaCurrent)
         {
         Trade(1);
         }
   }
return;
}