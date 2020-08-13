//+------------------------------------------------------------------+
//|                                           HLHB Trend-Catcher.mq4 |
//|                                                        Martian4x |
//|                                        https://www.martian4x.com |
//+------------------------------------------------------------------+
#property strict
// Preprocessor 
#include <TradingFunctions.mqh>
// External Variables 
extern bool DynamicLotSize = true; 
extern bool AllowTrailingStop = true; 
extern bool UseTrendMA = true; 
extern double EquityPercent = 5; 
extern double FixedLotSize = 0.01;
extern double StopLoss = 100; 
extern double TakeProfit = 300; 
//extern int TrailingStop = 100; 
//extern int MinimumProfit = 30;
extern int Slippage = 5; 
extern int AdjustPips = 3;
extern int MagicNumber = 1112; 
extern int FastMAPeriod = 5; 
extern int SlowMAPeriod = 10;
extern int TrendMAPeriod = 60;
extern int RSIPeriod = 10;
// extern int ADXPeriod = 14;
// extern int ADXCrossValue = 25;
// Strategy 1, EA Version 1, TradingFunctions 1, Symbol, Properties 1
// Strategy 1, EA Version 1, TradingFunctions 1, Symbol, Properties 2
//extern double StopLoss = 150; 
//extern double TakeProfit = 400; 
//extern int TrailingStop = 150; 
//extern int MinimumProfit = 150;
//extern int ADXPeriod = 14// >25
// Global Variables 
int BuyTicket; 
int SellTicket; 
double UsePoint; 
int UseSlippage;
string StatusComment = "";
string AccountType;
int TrailingStop = StopLoss;
int MinimumProfit = TrailingStop;
string TicketNumber;
bool TrendMABuy;
bool TrendMASell;

//bool placeOrder;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------tkt-----------------------------+
int OnInit()
  {
//---
    // Check if the live trading is allowed
    if(IsTradeAllowed() == false) 
      Alert("Enable the setting \'Allow live trading\' in the Expert Properties!");
    if(IsDemo()) 
      AccountType = "Demo Account"; else AccountType =  "Real Account"; 

    UsePoint = PipPoint(Symbol()); 
    UseSlippage = GetSlippage(Symbol(),Slippage); 

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
    double PreviousSlowMA = iMA(NULL, 0, SlowMAPeriod, 0, MODE_EMA, PRICE_CLOSE, 2);
    double CurrentSlowMA = iMA(NULL, 0, SlowMAPeriod, 0, MODE_EMA, PRICE_CLOSE, 1);
    double PreviousFastMA = iMA(NULL, 0, FastMAPeriod, 0, MODE_EMA, PRICE_CLOSE, 2);
    double CurrentFastMA = iMA(NULL, 0, FastMAPeriod, 0, MODE_EMA, PRICE_CLOSE, 1);
    double PreviousRSI = iRSI( NULL, 0, RSIPeriod, PRICE_MEDIAN, 2);
    double CurrentRSI = iRSI( NULL, 0, RSIPeriod, PRICE_MEDIAN, 1);
    // double PreviousADX = iADX( NULL, 0, ADXPeriod, PRICE_CLOSE, 0, 2);
    // double CurrentADX = iADX( NULL, 0, ADXPeriod, PRICE_CLOSE, 0, 1);

  // TrendMA Buy
    if(UseTrendMA==true){
      double CurrentTrendMA = iMA(NULL, 0, TrendMAPeriod, 0, MODE_SMA, PRICE_CLOSE, 1);
      if(CurrentFastMA > CurrentTrendMA){
        TrendMABuy = true;
      } else {
        TrendMABuy = false;
      }
    }
    
    // Lot size calculation 
    double LotSize;
    LotSize = CalcLotSize(DynamicLotSize,EquityPercent,StopLoss,FixedLotSize);

    // Lot size verification
    LotSize = VerifyLotSize(LotSize);

    // Buy Order Condition
    if(PreviousFastMA < PreviousSlowMA && CurrentFastMA > CurrentSlowMA  && BuyMarketCount(Symbol(),MagicNumber) == 0){ // Check if the EA has already opened buy orders
      // if(PreviousRSI < 50.0 && CurrentRSI > 50.0 && PreviousADX < 25.0 && CurrentADX > 25.0){
      //if(PreviousRSI < 50.0 && CurrentRSI > 50.0 && CurrentADX > 25.0){
      if(PreviousRSI < 50.0 && CurrentRSI > 50.0){
        if((UseTrendMA==true && TrendMABuy ==true) || UseTrendMA == false){
          // if(PreviousRSI < 50.0 && CurrentRSI > 50.0){
          // Close Previous Order
          // CloseOrder(SellTicket);

          // Close EA sell orders 
          if(SellMarketCount(Symbol(),MagicNumber) > 0) { 
            CloseAllSellOrders(Symbol(),MagicNumber,Slippage); 
          }

          // Buy Order Open
          BuyTicket = OpenBuyOrder(Symbol(), LotSize, UseSlippage,MagicNumber); // REMEMBER:  Order has no StopLoss and TakeProfit values
          // Order StopLoss and TakeProfit
          if(BuyTicket > 0 && (StopLoss > 0 || TakeProfit > 0)) { 
            TicketNumber = BuyTicket;
            OrderSelect(BuyTicket,SELECT_BY_TICKET);  
            double OpenPrice = OrderOpenPrice();
            double BuyStopLoss = CalcBuyStopLoss(Symbol(),StopLoss,OpenPrice); 
            if(BuyStopLoss > 0) { 
              BuyStopLoss = AdjustBelowStopLevel(Symbol(),BuyStopLoss,AdjustPips); 
            }       
            double BuyTakeProfit = CalcBuyTakeProfit(Symbol(),TakeProfit,OpenPrice);  
            if(BuyTakeProfit > 0) { 
              BuyTakeProfit = AdjustAboveStopLevel(Symbol(),BuyTakeProfit,AdjustPips); 
            }
            AddStopProfit(BuyTicket,BuyStopLoss,BuyTakeProfit); 
          }
          StatusComment = "Buy order :"+BuyTicket+" placed";

        }
      }
    } // End of Buy Order

    

  // TrendMA Sell
    if(UseTrendMA==true){
      double CurrentTrendMA = iMA(NULL, 0, TrendMAPeriod, 0, MODE_SMA, PRICE_CLOSE, 1);
      if(CurrentFastMA < CurrentTrendMA){
        TrendMASell = true;
      } else {
        TrendMASell = false;
      }
    }

    // Sell Order Condition
    if(PreviousFastMA > PreviousSlowMA && CurrentFastMA < CurrentSlowMA && SellMarketCount(Symbol(),MagicNumber) == 0){ // Check if the SellTicket needs to be 0 before placing a new order
      // if(PreviousRSI > 50.0 && CurrentRSI < 50.0 && PreviousADX > 25.0 && CurrentADX < 25.0){
      //if(PreviousRSI > 50.0 && CurrentRSI < 50.0 && CurrentADX > 25.0){
       if(PreviousRSI > 50.0 && CurrentRSI < 50.0){
        if((UseTrendMA==true && TrendMASell==true) || UseTrendMA == false){
          // if(PreviousRSI > 50.0 && CurrentRSI < 50.0 ){
          // Close Previous Orders
          // CloseOrder(BuyTicket);
          // Close all EA opened Buy Orders
          if(BuyMarketCount(Symbol(),MagicNumber) > 0) { 
            CloseAllBuyOrders(Symbol(),MagicNumber,Slippage); 
          }
          // Sell Order Open
          SellTicket = OpenSellOrder(Symbol(), LotSize, UseSlippage,MagicNumber); // REMEMBER:  Order has no StopLoss and TakeProfit values
          // Order StopLoss and TakeProfit
          if(SellTicket > 0 && (StopLoss > 0 || TakeProfit > 0)) { 
            TicketNumber = SellTicket;
            OrderSelect(SellTicket,SELECT_BY_TICKET);    
            double OpenPrice = OrderOpenPrice();         
            double SellStopLoss = CalcSellStopLoss(Symbol(),StopLoss,OpenPrice);    
            if(SellStopLoss > 0) { 
              SellStopLoss = AdjustAboveStopLevel(Symbol(),SellStopLoss,AdjustPips); 
            }         
            double SellTakeProfit = CalcSellTakeProfit(Symbol(),TakeProfit,OpenPrice);    
            if(SellTakeProfit > 0) { 
              SellTakeProfit = AdjustBelowStopLevel(Symbol(),SellTakeProfit,AdjustPips); 
            }
            AddStopProfit(SellTicket,SellStopLoss,SellTakeProfit);  
          } 
          StatusComment = "Sell order :"+SellTicket+" placed";

        }
      }
    } // End of Sell Order

    if(AllowTrailingStop==true){
      // Adjust trailing stops 
      if(BuyMarketCount(Symbol(),MagicNumber) > 0 && TrailingStop > 0) { 
        BuyTrailingStop(Symbol(),TrailingStop,MinimumProfit,MagicNumber); 
      }
      if(SellMarketCount(Symbol(),MagicNumber) > 0 && TrailingStop > 0) { 
        SellTrailingStop(Symbol(),TrailingStop,MinimumProfit,MagicNumber); 
      }
    }

    // Chart Comment
    string AccountInfo = "Type: "+AccountType+", Leverage: "+AccountLeverage()+", Broker: "+AccountInfoString(ACCOUNT_COMPANY)+", Server: "+AccountInfoString(ACCOUNT_SERVER)+", AccountName: "+AccountName(); 
    string SettingsComment = "DynamicLotSize: "+DynamicLotSize+", EquityPercent: "+EquityPercent+", FixedLotSize: "+FixedLotSize+", StopLoss: "+StopLoss+", TakeProfit: "+TakeProfit; 
    string Settings2Comment = "TrailingStop: "+TrailingStop+", MinimumProfit: "+MinimumProfit+", Slippage: "+Slippage+", AdjustPips: "+AdjustPips+", MagicNumber: "+MagicNumber; 
    string IndicatorsComment = "FastMAPeriod: "+FastMAPeriod+", SlowMAPeriod: "+SlowMAPeriod+" RSIPeriod: "+RSIPeriod+", TrendMAPeriod: "+TrendMAPeriod; 
    Comment(AccountInfo+"\n"+SettingsComment+"\n"+Settings2Comment+"\n"+IndicatorsComment+"\n"+StatusComment);
    
  } // End of OnTick
//+------------------------------------------------------------------+
