//+------------------------------------------------------------------+
//|                                                         test.mq4 |
//|                                                     Juan Ludevid |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Juan Ludevid"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#include <CustomFunctions01.mqh>

int bbPeriod = 20;
int band1Std = 1;
int band2Std = 4;
int magicNumber = 22222;
input double riskPerTrade = 0.02;
int orderID;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
    Alert("");
    Alert("The EA has started.");

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
      Alert("");
      Alert("The EA has finished.");
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
    Alert("");
   
   //---narrow bands
   double bbLower1 = iBands(NULL,0,bbPeriod,band1Std,0,PRICE_CLOSE,MODE_LOWER,0);
   double bbUpper1 = iBands(NULL,0,bbPeriod,band1Std,0,PRICE_CLOSE,MODE_UPPER,0);
   double bbMid = iBands(NULL,0,bbPeriod,band1Std,0,PRICE_CLOSE,0,0);
   //--- wider bands 
   double bbLower2 = iBands(NULL,0,bbPeriod,band2Std,0,PRICE_CLOSE,MODE_LOWER,0);
   double bbUpper2 = iBands(NULL,0,bbPeriod,band2Std,0,PRICE_CLOSE,MODE_UPPER,0);
   //--- Check if there are no orders alredy placed 
   
   if(!CheckIfOpenOrdersByMagicNumber(magicNumber) // if no open orders, get into new position
   {
      if(Ask < bbLower1)//buying
      {
         Alert("Price is bellow bbLower1, Sending buy order");
         double stopLossPrice = NormalizeDouble(bbLower2,Digits);
         double takeProfitPrice = NormalizeDouble(bbMid,Digits);;
         Alert("Entry Price = " + Ask);
         Alert("Stop Loss Price = " + stopLossPrice);
         Alert("Take Profit Price = " + takeProfitPrice);
         
         orderID = OrderSend(NULL,OP_BUYLIMIT,0.01,Ask,10,stopLossPrice,takeProfitPrice,NULL,magicNumber);
         if(orderID < 0) Alert("order rejected. Order error: " + GetLastError());
      }
      else if(Bid > bbUpper1)//shorting
      {
         Alert("Price is above bbUpper1, Sending short order");
         double stopLossPrice = NormalizeDouble(bbUppe  r2,Digits);
         double takeProfitPrice = NormalizeDouble(bbMid,Digits);
         Alert("Entry Price = " + Bid);
         Alert("Stop Loss Price = " + stopLossPrice);
         Alert("Take Profit Price = " + takeProfitPrice);
   	  
   	  orderID = OrderSend(NULL,OP_SELLLIMIT,0.01,Bid,10,stopLossPrice,takeProfitPrice,NULL,magicNumber);
   	  if(orderID < 0) Alert("order rejected. Order error: " + GetLastError());
      }
     // else {Alert("No signal was found.");
      
    } 
    else  // if position already opened, update if required
    {
    Alert("Order already open");
    if(OrderSelect(orderID,SELECT_BY_TICKET))
    {
      int orderType = OrderType() // OrderType() returns whether it is a long/short position 0= long, 1=short
      
      double currentExitPoint;
      if(orderType == 0)
      {
         currentExitPoint = NormalizeDouble(bbLower2,Digits); // it is long so, hit stop loss if price goes down
      }
      else 
      {
         currentExitPoint = NormalizeDouble(bbUpper2,Digits); // it is short so, hit stop loss if price goes up
      }
    }
    }
  }
//+------------------------------------------------------------------+
