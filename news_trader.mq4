//+------------------------------------------------------------------+
//|                                                  news_trader.mq4 |
//|                                                     Juan Ludevid |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Juan Ludevid"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict


// Input parameters
input double LotSize = 0.1;                 // Lot size
input int Slippage = 3;                     // Maximum slippage (in points)
input int DistancePips = 12;                // Distance from ask price (in pips)
input int StopLossPips = 12;                // Stop loss distance (in pips)
input int NewsMinutes = 3;                  // Minutes before news to set orders
input string NewsTime = "15:30";            // Time of the news release (hh:mm, broker time)

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
void OnTick()
  {
//---
    static bool OrdersPlaced = false;       // Prevent placing orders multiple times

    datetime NewsReleaseTime = StrToTime(StringConcatenate(TimeToString(TimeCurrent(), TIME_DATE), " ", NewsTime));
    datetime CurrentTime = TimeCurrent();

    // Check if it's 3 minutes before the news release
    if ((NewsReleaseTime - CurrentTime) <= (NewsMinutes * 60) && !OrdersPlaced) {
        double AskPrice = NormalizeDouble(Ask, Digits);
        double BidPrice = NormalizeDouble(Bid, Digits);
        double BuyStopPrice = NormalizeDouble(AskPrice + DistancePips * Point, Digits);
        double SellStopPrice = NormalizeDouble(BidPrice - DistancePips * Point, Digits);
        double StopLoss = NormalizeDouble(AskPrice, Digits);

        // Place buy stop order
        int BuyOrder = OrderSend(
            Symbol(),
            OP_BUYSTOP,
            LotSize,
            BuyStopPrice,
            Slippage,
            StopLoss,
            0,
            "News Buy Order",
            0,
            0,
            clrBlue
        );

        // Place sell stop order
        int SellOrder = OrderSend(
            Symbol(),
            OP_SELLSTOP,
            LotSize,
            SellStopPrice,
            Slippage,
            StopLoss,
            0,
            "News Sell Order",
            0,
            0,
            clrRed
        );

        // Check for errors
        if (BuyOrder < 0 || SellOrder < 0) {
            Print("Error placing orders: ", ErrorDescription(GetLastError()));
        } else {
            Print("Orders placed successfully.");
            OrdersPlaced = true;
        }
    }

    return 0;
}

string ErrorDescription(int error) {
    switch (error) {
        case ERR_NO_ERROR: return "No error";
        case ERR_INVALID_TRADE_PARAMETERS: return "Invalid trade parameters";
        case ERR_NOT_ENOUGH_MONEY: return "Not enough money";
        case ERR_TRADE_TIMEOUT: return "Trade timeout";
        // Add more error cases if needed
        default: return "Unknown error";
    }
  }
//+------------------------------------------------------------------+
