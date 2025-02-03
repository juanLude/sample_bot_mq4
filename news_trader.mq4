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
input double LotSize = 0.02;
input int Slippage = 20;
input int DistancePips = 12;
input int StopLossPips = 12;
input int NewsMinutes = 3;
input string NewsTime = "02:30";

int BuyOrderTicket = -1;
int SellOrderTicket = -1;
bool OrdersPlaced = false;
bool OrderExecuted = false;

int OnInit() {
    Alert("Starting News Strategy");
    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
    Alert("Stopping News Strategy");
}

void CancelOrder(int ticket) {
    if (OrderSelect(ticket, SELECT_BY_TICKET)) {
        if (OrderType() == OP_BUYSTOP || OrderType() == OP_SELLSTOP) {
            if (OrderDelete(ticket)) {
                Print("Order ", ticket, " canceled successfully.");
            } else {
                Print("Error canceling order ", ticket, ": ", GetLastError());
            }
        }
    }
}

void OnTick() {
    datetime NewsReleaseTime = StrToTime(StringConcatenate(TimeToString(TimeCurrent(), TIME_DATE), " ", NewsTime));
    datetime CurrentTime = TimeCurrent();
    
    double AskPrice = NormalizeDouble(Ask, Digits);
    double BidPrice = NormalizeDouble(Bid, Digits);
    double BuyStopPrice = NormalizeDouble(AskPrice + DistancePips * Point, Digits);
    double SellStopPrice = NormalizeDouble(BidPrice - DistancePips * Point, Digits);
    double BuyStopLoss = NormalizeDouble(AskPrice - StopLossPips * Point, Digits);
    double SellStopLoss = NormalizeDouble(BidPrice + StopLossPips * Point, Digits);
    
    if ((NewsReleaseTime - CurrentTime) <= (NewsMinutes * 60) && !OrdersPlaced) {
        BuyOrderTicket = OrderSend(Symbol(), OP_BUYSTOP, LotSize, BuyStopPrice, Slippage, BuyStopLoss, 0, "News Buy Order", 0, 0, clrBlue);
        SellOrderTicket = OrderSend(Symbol(), OP_SELLSTOP, LotSize, SellStopPrice, Slippage, SellStopLoss, 0, "News Sell Order", 0, 0, clrRed);
        
        if (BuyOrderTicket < 0 || SellOrderTicket < 0) {
            Print("Error placing orders: ", GetLastError());
        } else {
            Print("Orders placed successfully.");
            OrdersPlaced = true;
        }
    }
    
    if (OrdersPlaced && !OrderExecuted) {
        if (OrderSelect(BuyOrderTicket, SELECT_BY_TICKET)) {
            if (OrderType() == OP_BUYSTOP) {
                if (!OrderModify(BuyOrderTicket, BuyStopPrice, BuyStopLoss, 0, 0, clrBlue)) {
                    Print("Error modifying Buy Stop order: ", GetLastError());
                }
            }
        }
        if (OrderSelect(SellOrderTicket, SELECT_BY_TICKET)) {
            if (OrderType() == OP_SELLSTOP) {
                if (!OrderModify(SellOrderTicket, SellStopPrice, SellStopLoss, 0, 0, clrRed)) {
                    Print("Error modifying Sell Stop order: ", GetLastError());
                }
            }
        }
    }
    
    for (int i = OrdersTotal() - 1; i >= 0; i--) {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            if (OrderTicket() == BuyOrderTicket && OrderType() == OP_BUY) {
                CancelOrder(SellOrderTicket);
                OrderExecuted = true;
                Alert("Sell Order has been cancelled");
            } else if (OrderTicket() == SellOrderTicket && OrderType() == OP_SELL) {
                CancelOrder(BuyOrderTicket);
                OrderExecuted = true;
                Alert("Buy Order has been cancelled");
            }
        }
    }
}



//+------------------------------------------------------------------+
