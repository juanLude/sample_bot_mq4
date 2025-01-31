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
input string NewsTime = "17:00";            // Time of the news release (hh:mm, broker time)

int BuyOrderTicket = -1;                    // Ticket for the buy order
int SellOrderTicket = -1;                   // Ticket for the sell order
bool OrdersPlaced = false;                  // Prevent placing orders multiple times

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   Alert("Starting News Strategy");
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   Alert("Stopping News Strategy");
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
    datetime NewsReleaseTime = StrToTime(StringConcatenate(TimeToString(TimeCurrent(), TIME_DATE), " ", NewsTime));
    datetime CurrentTime = TimeCurrent();

    // Check if it's 3 minutes before the news release
    if ((NewsReleaseTime - CurrentTime) <= (NewsMinutes * 60) && !OrdersPlaced) {
        double AskPrice = NormalizeDouble(Ask, Digits);
        double BidPrice = NormalizeDouble(Bid, Digits);
        double BuyStopPrice = NormalizeDouble(AskPrice + DistancePips * Point, Digits);
        double SellStopPrice = NormalizeDouble(BidPrice - DistancePips * Point, Digits);

        // Place buy stop order
        BuyOrderTicket = OrderSend(
            Symbol(),
            OP_BUYSTOP,
            LotSize,
            BuyStopPrice,
            Slippage,
            NormalizeDouble(BuyStopPrice - StopLossPips * Point, Digits),
            0,
            "News Buy Order",
            0,
            0,
            clrBlue
        );

        // Place sell stop order
        SellOrderTicket = OrderSend(
            Symbol(),
            OP_SELLSTOP,
            LotSize,
            SellStopPrice,
            Slippage,
            NormalizeDouble(SellStopPrice + StopLossPips * Point, Digits),
            0,
            "News Sell Order",
            0,
            0,
            clrRed
        );

        // Check for errors
        if (BuyOrderTicket < 0 || SellOrderTicket < 0) {
            Print("Error placing orders: ", ErrorDescription(GetLastError()));
        } else {
            Print("Orders placed successfully.");
            OrdersPlaced = true;
        }
    }

    // Adjust stop losses to maintain a 12-pip distance from current prices
    if (OrdersPlaced) {
        double AskPrice = NormalizeDouble(Ask, Digits);
        double BidPrice = NormalizeDouble(Bid, Digits);

        if (OrderSelect(BuyOrderTicket, SELECT_BY_TICKET)) {
            if (OrderType() == OP_BUYSTOP) {
                OrderModify(
                    BuyOrderTicket,
                    OrderOpenPrice(),
                    NormalizeDouble(OrderOpenPrice() - StopLossPips * Point, Digits),
                    0,
                    0,
                    clrBlue
                );
            }
        }

        if (OrderSelect(SellOrderTicket, SELECT_BY_TICKET)) {
            if (OrderType() == OP_SELLSTOP) {
                OrderModify(
                    SellOrderTicket,
                    OrderOpenPrice(),
                    NormalizeDouble(OrderOpenPrice() + StopLossPips * Point, Digits),
                    0,
                    0,
                    clrRed
                );
            }
        }
    }

    // Monitor orders and cancel the opposite order if one is executed
    for (int i = OrdersTotal() - 1; i >= 0; i--) {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            // Check if a buy stop order was executed
            if (OrderTicket() == BuyOrderTicket && OrderType() == OP_BUY) {
                CancelOrder(SellOrderTicket);
                BuyOrderTicket = -1;  // Reset ticket to avoid multiple cancellations
            }
            // Check if a sell stop order was executed
            else if (OrderTicket() == SellOrderTicket && OrderType() == OP_SELL) {
                CancelOrder(BuyOrderTicket);
                SellOrderTicket = -1;  // Reset ticket to avoid multiple cancellations
            }
        }
    }
}

void CancelOrder(int ticket) {
    if (OrderSelect(ticket, SELECT_BY_TICKET)) {
        if (OrderType() == OP_BUYSTOP || OrderType() == OP_SELLSTOP) {
            bool canceled = OrderDelete(ticket);
            if (canceled) {
                Print("Order ", ticket, " canceled successfully.");
            } else {
                Print("Error canceling order ", ticket, ": ", ErrorDescription(GetLastError()));
            }
        }
    }
}

string ErrorDescription(int error) {
    switch (error) {
        case ERR_NO_ERROR: return "No error";
        case ERR_INVALID_TRADE_PARAMETERS: return "Invalid trade parameters";
        case ERR_NOT_ENOUGH_MONEY: return "Not enough money";
        case ERR_TRADE_TIMEOUT: return "Trade timeout";
        // Add more error cases if needed
        default: return "Unknown error";
    }  }
//+------------------------------------------------------------------+
