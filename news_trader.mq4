//+------------------------------------------------------------------+
//|                                                  news_trader.mq4 |
//|                                                     Juan Ludevid |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Juan Ludevid"
#property link      "https://www.mql5.com"
#property version   "1.01"
#property strict

// Input parameters
input double LotSize = 0.1;
input int Slippage = 20;
input int DistancePips = 6; // change back to 12
input int StopLossPips = 6; // change back to 12
input int BreakEvenPips = 5;
input int TrailingStopPips = 10;
input int NewsMinutes = 1; // place buy and sell stop orders 1 minute prior to news release
input string NewsTime = "02:30";

int BuyOrderTicket = -1;
int SellOrderTicket = -1;
bool OrdersPlaced = false;
bool OrderExecuted = false;
bool BuyOrderCancelled = false;
bool SellOrderCancelled = false;

int OnInit() {
    Alert("Starting News Strategy");
    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
    Alert("News Strategy Stopped");
}

void CancelOrder(int ticket) {
    if (OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) {
        if (OrderType() == OP_BUYSTOP || OrderType() == OP_SELLSTOP) {
            if (OrderDelete(ticket)) {
                Print("Order ", ticket, " canceled successfully.");
            } else {
                Print("Error canceling order ", ticket, ": ", GetLastError());
            }
        }
    }
}

void AdjustStopLoss(int ticket, double newStopLoss) {
    if (OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) {
        if (OrderModify(ticket, OrderOpenPrice(), newStopLoss, 0, 0, clrNONE)) {
            Print("Stop loss adjusted for order ", ticket, " to ", newStopLoss);
        } else {
            Print("Error modifying stop loss: ", GetLastError());
        }
    }
}

void OnTick() {
    datetime NewsReleaseTime = StrToTime(StringConcatenate(TimeToString(TimeCurrent(), TIME_DATE), " ", NewsTime));
    datetime CurrentTime = TimeCurrent();
    
    double AskPrice = NormalizeDouble(Ask, Digits);
    double BidPrice = NormalizeDouble(Bid, Digits);
    double BuyStopPrice = NormalizeDouble(AskPrice + DistancePips * Point, Digits);
    double SellStopPrice = NormalizeDouble(BidPrice, Digits);
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
    
    for (int i = OrdersTotal() - 1; i >= 0; i--) {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            int orderType = OrderType();
            double orderOpenPrice = OrderOpenPrice();
            double currentStopLoss = OrderStopLoss();
            
            if (OrderTicket() == BuyOrderTicket && orderType == OP_BUY) {
                if (BidPrice >= orderOpenPrice + (BreakEvenPips * Point) && currentStopLoss < orderOpenPrice) {
                    AdjustStopLoss(BuyOrderTicket, orderOpenPrice);
                }
                if (BidPrice >= currentStopLoss + (TrailingStopPips * Point)) {
                    AdjustStopLoss(BuyOrderTicket, BidPrice - (TrailingStopPips * Point));
                }
                if (!SellOrderCancelled) {
                    CancelOrder(SellOrderTicket);
                    OrderExecuted = true;
                    SellOrderTicket = -1;
                    Alert("Sell Order has been cancelled");
                    SellOrderCancelled = true;
                }
            } 
            else if (OrderTicket() == SellOrderTicket && orderType == OP_SELL) {
                if (AskPrice <= orderOpenPrice - (BreakEvenPips * Point) && currentStopLoss > orderOpenPrice) {
                    AdjustStopLoss(SellOrderTicket, orderOpenPrice);
                }
                if (AskPrice <= currentStopLoss - (TrailingStopPips * Point)) {
                    AdjustStopLoss(SellOrderTicket, AskPrice + (TrailingStopPips * Point));
                }
                if (!BuyOrderCancelled) {
                    CancelOrder(BuyOrderTicket);
                    OrderExecuted = true;
                    BuyOrderTicket = -1;
                    Alert("Buy Order has been cancelled");
                    BuyOrderCancelled = true;
                }
            }
        }
    }
}
