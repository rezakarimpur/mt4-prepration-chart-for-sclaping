//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("Combined nima Initialized.");
    ChartSetInteger(0, CHART_SCALE, 0);           // Set chart scale (smallest possible value)
    ChartSetInteger(0, CHART_WIDTH_IN_BARS, 1);   // Minimum number of bars visible (zoom all the way in)

    // Set chart properties

    ChartSetInteger(0, CHART_MODE, CHART_CANDLES);  // Set chart to candlestick
    ChartSetInteger(0, CHART_SHOW_GRID, false);     // Turn off grid
    ChartSetInteger(0, CHART_FOREGROUND, true);     // Enable foreground mode
    ChartSetInteger(0, CHART_COLOR_BACKGROUND, clrBlack);    // Background color
    ChartSetInteger(0, CHART_COLOR_FOREGROUND, clrWhite);    // Foreground color
    //ChartSetInteger(0, CHART_COLOR_BULL_CANDLE, clrLimeGreen); // Bull candle color
    //ChartSetInteger(0, CHART_COLOR_BEAR_CANDLE, clrGold);    // Bear candle color
    DisplayCloseAndHighLowLines();
    
    
    // draw half an hour chart
    DrawHalfHourLinesToday();
    /// today open
    DrawTodayOpenLine();
////
    CreateScaleFixButton(); // Create the button on initialization

    return(INIT_SUCCEEDED);
    
    
    
    
        // drawing 2300 of yesterday

}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // ObjectsDeleteAll(); // Remove all chart objects
   
    ObjectDelete("ScaleFixButton"); // Removes the button
    ObjectDelete("SwingPointButton"); // Removes the Swing Point button
    Print("Combined EA Deinitialized.");
    Print("Combined EA Deinitialized.");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Handle Stop Loss and Take Profit modifications
    UpdateSLTP();

    // Update Stop Loss history display
    DrawStopLossHistory();
     // Display round numbers for all active orders
    DisplayRoundNumbers();
    

    
    /// swing points
    DisplaySwingPoints();
    /// counting stop loss
    DrawStopLossHistory(); // Initialize Stop Loss history display
    DetectBreakouts(20);//
    DrawOpen1630Candle(); //draw 1630 open
    DrawTrendLines();
    CheckTrendLineBreaks();

}

void CheckTrendLineBreaks()
{
    int totalObjects = ObjectsTotal();
    double currentPrice = Bid; // You can also use Ask depending on the breakout logic

    for (int i = 0; i < totalObjects; i++) {
        string objName = ObjectName(i);

        // Only check for objects that are trendlines
        if (ObjectType(objName) == OBJ_TREND) {
            double price1 = ObjectGetDouble(0, objName, OBJPROP_PRICE1); // First price point
            double price2 = ObjectGetDouble(0, objName, OBJPROP_PRICE2); // Second price point
            datetime time1 = ObjectGetInteger(0, objName, OBJPROP_TIME1); // First time point
            datetime time2 = ObjectGetInteger(0, objName, OBJPROP_TIME2); // Second time point

            // Calculate the price of the trendline at the current time
            if (TimeCurrent() >= time1 && TimeCurrent() <= time2) {
                double slope = (price2 - price1) / (time2 - time1); // Slope of the trendline
                double intercept = price1 - slope * time1;         // Intercept of the trendline
                double expectedPrice = slope * TimeCurrent() + intercept;

                // Check for a breakout
                if ((currentPrice > expectedPrice && price1 < price2) ||  // Break above for upward trendlines
                    (currentPrice < expectedPrice && price1 > price2)) { // Break below for downward trendlines
                    Print("Trendline Breakout Detected: ", objName);
                    Alert("Trendline Breakout Detected: ", objName);
                }
            }
        }
    }
}

void DetectBreakouts(int barsToCheck)
{
    // Initialize variables
    double highestHigh = -1.0;  // Highest price in the range
    double lowestLow = 1e8;     // Lowest price in the range
    int rangeBars = barsToCheck; // Number of bars to calculate range

    // Loop through the last N bars to determine the range
    for (int i = 1; i <= rangeBars; i++) {
        if (High[i] > highestHigh) highestHigh = High[i];
        if (Low[i] < lowestLow) lowestLow = Low[i];
    }

    // Get the current price
    double currentPrice = Bid;

    // Check for Bullish Breakout
    if (currentPrice > highestHigh) {
        string breakoutLineName = "BullishBreakoutLine";
        if (ObjectFind(0, breakoutLineName) == -1) {
            ObjectCreate(0, breakoutLineName, OBJ_HLINE, 0, 0, highestHigh);
            ObjectSetInteger(0, breakoutLineName, OBJPROP_COLOR, clrLime); // Green line for bullish breakout
            ObjectSetInteger(0, breakoutLineName, OBJPROP_WIDTH, 2);
            Print("Bullish Breakout detected at price: ", currentPrice);
            Alert("Bullish Breakout detected at price: ", currentPrice);
        }
    }

    // Check for Bearish Breakout
    if (currentPrice < lowestLow) {
        breakoutLineName = "BearishBreakoutLine";
        if (ObjectFind(0, breakoutLineName) == -1) {
            ObjectCreate(0, breakoutLineName, OBJ_HLINE, 0, 0, lowestLow);
            ObjectSetInteger(0, breakoutLineName, OBJPROP_COLOR, clrRed); // Red line for bearish breakout
            ObjectSetInteger(0, breakoutLineName, OBJPROP_WIDTH, 2);
            Print("Bearish Breakout detected at price: ", currentPrice);
            Alert("Bearish Breakout detected at price: ", currentPrice);
        }
    }
}

void DrawOpen1630Candle()
{
    // Get the current time
    datetime currentTime = TimeCurrent();

    // Get the start time of today
    datetime todayStart = iTime(Symbol(), PERIOD_D1, 0);

    // Calculate the time for the 16:30 candle
    datetime time1630 = todayStart + (16 * 3600) + (30 * 60); // 16:30 = 16 hours + 30 minutes

    // Check if the current time is 16:30 or later
    if (currentTime >= time1630) {
        // Find the open price of the 16:30 candle in the M1 timeframe
        int index1630 = iBarShift(Symbol(), PERIOD_M1, time1630, true);
        if (index1630 < 0) {
            Print("Error: Unable to find the 16:30 candle.");
            return;
        }

        double openPrice1630 = iOpen(Symbol(), PERIOD_M1, index1630);

        // Define a unique name for the line
        string lineName = "Open1630Line";

        // Check if the line already exists
        if (ObjectFind(0, lineName) == -1) {
            // Create a horizontal line at the 16:30 open price
            if (ObjectCreate(0, lineName, OBJ_HLINE, 0, 0, openPrice1630)) {
                ObjectSetInteger(0, lineName, OBJPROP_COLOR, clrBlue); // Set line color to Blue
                ObjectSetInteger(0, lineName, OBJPROP_WIDTH, 2);       // Set line width
                ObjectSetInteger(0, lineName, OBJPROP_STYLE, STYLE_SOLID); // Solid line
                Print("16:30 Open price line drawn: ", openPrice1630);
            } else {
                Print("Failed to create 16:30 Open line. Error: ", GetLastError());
            }
        } else {
            Print("16:30 Open line already exists.");
        }
    } else {
        Print("Current time is before 16:30.");
    }
}

bool showTrendLines = false;  // Toggle for trendlines



//+------------------------------------------------------------------+
//| Create buttons                                                  |
//+------------------------------------------------------------------+

bool showSwingPoints = false; // Global variable to toggle Swing Points
void CreateScaleFixButton()
{
    string scaleFixButton = "ScaleFixButton";
    string swingPointButton = "SwingPointButton";
    string trendLineButton = "TrendLineButton";
    if (ObjectFind(0, scaleFixButton) == -1) {
        ObjectCreate(0, scaleFixButton, OBJ_BUTTON, 0, 0, 0);
        ObjectSetInteger(0, scaleFixButton, OBJPROP_CORNER, 2);
        ObjectSetInteger(0, scaleFixButton, OBJPROP_XDISTANCE, 10);
        ObjectSetInteger(0, scaleFixButton, OBJPROP_YDISTANCE, 40);
        ObjectSetInteger(0, scaleFixButton, OBJPROP_XSIZE, 120);
        ObjectSetInteger(0, scaleFixButton, OBJPROP_YSIZE, 30);
        ObjectSetString(0, scaleFixButton, OBJPROP_TEXT, "Toggle Scale Fix");
        ObjectSetInteger(0, scaleFixButton, OBJPROP_COLOR, clrBlack);
        ObjectSetInteger(0, scaleFixButton, OBJPROP_STYLE, STYLE_SOLID);
    }

    if (ObjectFind(0, swingPointButton) == -1) {
        ObjectCreate(0, swingPointButton, OBJ_BUTTON, 0, 0, 0);
        ObjectSetInteger(0, swingPointButton, OBJPROP_CORNER, 2);
        ObjectSetInteger(0, swingPointButton, OBJPROP_XDISTANCE, 10);
        ObjectSetInteger(0, swingPointButton, OBJPROP_YDISTANCE, 70);
        ObjectSetInteger(0, swingPointButton, OBJPROP_XSIZE, 120);
        ObjectSetInteger(0, swingPointButton, OBJPROP_YSIZE, 30);
        ObjectSetString(0, swingPointButton, OBJPROP_TEXT, "Toggle Swing Points");
        ObjectSetInteger(0, swingPointButton, OBJPROP_COLOR, clrBlack);
        ObjectSetInteger(0, swingPointButton, OBJPROP_STYLE, STYLE_SOLID);
    }

    // Trendline Button
    if (ObjectFind(0, trendLineButton) == -1) {
        ObjectCreate(0, trendLineButton, OBJ_BUTTON, 0, 0, 0);
        ObjectSetInteger(0, trendLineButton, OBJPROP_CORNER, 2);
        ObjectSetInteger(0, trendLineButton, OBJPROP_XDISTANCE, 10);
        ObjectSetInteger(0, trendLineButton, OBJPROP_YDISTANCE, 100);
        ObjectSetInteger(0, trendLineButton, OBJPROP_XSIZE, 120);
        ObjectSetInteger(0, trendLineButton, OBJPROP_YSIZE, 30);
        ObjectSetString(0, trendLineButton, OBJPROP_TEXT, "Toggle Trendlines");
        ObjectSetInteger(0, trendLineButton, OBJPROP_COLOR, clrBlack);
        ObjectSetInteger(0, trendLineButton, OBJPROP_STYLE, STYLE_SOLID);
    }





}

//+------------------------------------------------------------------+
//| Handle Button Clicks                                             |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
    if (id == CHARTEVENT_OBJECT_CLICK) {
        if (sparam == "ScaleFixButton") {
            bool scaleFixState = ChartGetInteger(0, CHART_SCALEFIX);
            scaleFixState = !scaleFixState;
            ChartSetInteger(0, CHART_SCALEFIX, scaleFixState);
            string newText = scaleFixState ? "Disable Scale Fix" : "Enable Scale Fix";
            ObjectSetString(0, "ScaleFixButton", OBJPROP_TEXT, newText);
            Print("Scale Fix toggled. New state: ", scaleFixState ? "Enabled" : "Disabled");
        }
        
        if (sparam == "SwingPointButton") {
            showSwingPoints = !showSwingPoints;
            newText = showSwingPoints ? "Hide Swing Points" : "Show Swing Points";
            ObjectSetString(0, "SwingPointButton", OBJPROP_TEXT, newText);
            if (!showSwingPoints) {
                ClearSwingPoints();
            }
        }
    
    
         if (sparam == "TrendLineButton") {
            showTrendLines = !showTrendLines;
            newText = showTrendLines ? "Hide Trendlines" : "Show Trendlines";
            ObjectSetString(0, "TrendLineButton", OBJPROP_TEXT, newText);
            if (!showTrendLines) {
               ClearTrendLines(); // Clear trendlines as well
            }
        }
    }
}
//+------------------------------------------------------------------+
//| Clear Trendlines                                                 |
//+------------------------------------------------------------------+
void ClearTrendLines()
{
    for (int i = ObjectsTotal() - 1; i >= 0; i--) {
        string objName = ObjectName(i);

        // Delete only trendlines
        if (StringFind(objName, "HighTrendline_") == 0 || StringFind(objName, "LowTrendline_") == 0) {
            ObjectDelete(objName);
        }
    }
    Print("All Trendlines cleared.");
}


void ClearSwingPoints()
{
    // Loop through all objects on the chart
    for (int i = ObjectsTotal() - 1; i >= 0; i--) {
        string objName = ObjectName(i);

        // Delete objects related to swing points and trendlines
        if (StringFind(objName, "SwingPoint_") == 0 || StringFind(objName, "HighTrendline_") == 0 || StringFind(objName, "LowTrendline_") == 0) {
            ObjectDelete(objName);
        }
    }

}

void DisplaySwingPoints()
{
    if (!showSwingPoints) return; // Only proceed if toggle is enabled

    int barsToCheck = 100; // Number of bars to analyze
    int swingCount = 0;

    for (int i = 1; i < barsToCheck; i++) {
        double currentHigh = High[i];
        double currentLow = Low[i];
        datetime currentTime = Time[i];

        // Detect Swing High
        if (currentHigh > High[i + 1] && currentHigh > High[i - 1]) {
            string highLabelName = StringFormat("SwingPoint_High_%d", swingCount++);
            ObjectCreate(0, highLabelName, OBJ_TEXT, 0, currentTime, currentHigh);
            ObjectSetText(highLabelName, StringFormat("High: %.2f", currentHigh), 10, "Arial", clrLime);
        }

        // Detect Swing Low
        if (currentLow < Low[i + 1] && currentLow < Low[i - 1]) {
            string lowLabelName = StringFormat("SwingPoint_Low_%d", swingCount++);
            ObjectCreate(0, lowLabelName, OBJ_TEXT, 0, currentTime, currentLow);
            ObjectSetText(lowLabelName, StringFormat("Low: %.2f", currentLow), 10, "Arial", clrRed);
        }
    }

    Print("Swing points detected and displayed.");
}

//+------------------------------------------------------------------+
//| Draw Trendlines                                                  |
//+------------------------------------------------------------------+
void DrawTrendLines()
{
    if (!showTrendLines) return; // Only proceed if toggle is enabled

    int barsToCheck = 100; // Number of bars to analyze
    double lastHighPrice = -1;
    double lastLowPrice = -1;
    datetime lastHighTime = 0;
    datetime lastLowTime = 0;

    for (int i = 1; i < barsToCheck; i++) {
        double currentHigh = High[i];
        double currentLow = Low[i];
        datetime currentTime = Time[i];

        // Detect Swing High and draw trendline
        if (currentHigh > High[i + 1] && currentHigh > High[i - 1]) {
            if (lastHighPrice != -1) {
                string highTrendlineName = StringFormat("HighTrendline_%d", i);
                ObjectCreate(0, highTrendlineName, OBJ_TREND, 0, lastHighTime, lastHighPrice, currentTime, currentHigh);
                ObjectSetInteger(0, highTrendlineName, OBJPROP_COLOR, clrLime);
                ObjectSetInteger(0, highTrendlineName, OBJPROP_WIDTH, 1);
                ObjectSetInteger(0, highTrendlineName, OBJPROP_RAY_RIGHT, false); // Disable ray

            }
            lastHighPrice = currentHigh;
            lastHighTime = currentTime;
        }

        // Detect Swing Low and draw trendline
        if (currentLow < Low[i + 1] && currentLow < Low[i - 1]) {
            if (lastLowPrice != -1) {
                string lowTrendlineName = StringFormat("LowTrendline_%d", i);
                ObjectCreate(0, lowTrendlineName, OBJ_TREND, 0, lastLowTime, lastLowPrice, currentTime, currentLow);
                ObjectSetInteger(0, lowTrendlineName, OBJPROP_COLOR, clrRed);
                ObjectSetInteger(0, lowTrendlineName, OBJPROP_WIDTH, 1);
                ObjectSetInteger(0, lowTrendlineName, OBJPROP_RAY_RIGHT, false); // Disable ray

            }
            lastLowPrice = currentLow;
            lastLowTime = currentTime;
        }
    }

    Print("Trendlines drawn based on swing points.");
}

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
double initialStopLoss = 0.0;  // To store the initial Stop Loss
double initialTakeProfit = 0.0; // To store the initial Take Profit

//+------------------------------------------------------------------+
//| Update Stop Loss and Take Profit                                 |
//+------------------------------------------------------------------+
void UpdateSLTP()
{
    int minStopLevel = MarketInfo(Symbol(), MODE_STOPLEVEL);
    double point = MarketInfo(Symbol(), MODE_POINT);
    double stopLevel = minStopLevel * point;

    for (int i = 0; i < OrdersTotal(); i++) {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            if (OrderType() == OP_BUY || OrderType() == OP_SELL) {
                double entryPrice = OrderOpenPrice();
                double fractionalPart = entryPrice - MathFloor(entryPrice);
                double stopLossPrice = 0;
                double takeProfitPrice = 0;

                // Calculate SL and TP based on logic
                if (OrderType() == OP_BUY) {
                    if (fractionalPart >= 0.5) {
                        stopLossPrice = MathFloor(entryPrice) + 0.5 - 1;
                        takeProfitPrice = MathFloor(entryPrice) + 0.5 + 2;
                    } else {
                        stopLossPrice = MathFloor(entryPrice) - 1;
                        takeProfitPrice = MathFloor(entryPrice) + 3;
                    }
                } else if (OrderType() == OP_SELL) {
                    if (fractionalPart >= 0.5) {
                        stopLossPrice = MathFloor(entryPrice) + 2;
                        takeProfitPrice = MathFloor(entryPrice) - 2;
                    } else {
                        stopLossPrice = MathFloor(entryPrice) + 1.5;
                        takeProfitPrice = MathFloor(entryPrice) - 2;
                    }
                }

                // Check if SL and TP are within the minimum stop level
                if (MathAbs(entryPrice - stopLossPrice) >= stopLevel &&
                    MathAbs(entryPrice - takeProfitPrice) >= stopLevel)
                {
                    // Check if SL or TP was manually changed
                    if (initialStopLoss == 0.0 && initialTakeProfit == 0.0) {
                        // Store the initial SL and TP
                        initialStopLoss = OrderStopLoss();
                        initialTakeProfit = OrderTakeProfit();
                    }

                    // If SL or TP is manually changed, skip modifying
                    if (OrderStopLoss() != initialStopLoss || OrderTakeProfit() != initialTakeProfit) {
                        Print("Manual SL/TP detected. Skipping modification for Order ", OrderTicket());
                        continue;
                    }

                    // Modify the order if SL or TP differs from calculated values
                    if (OrderStopLoss() != stopLossPrice || OrderTakeProfit() != takeProfitPrice) {
                        if (OrderModify(OrderTicket(), OrderOpenPrice(), stopLossPrice, takeProfitPrice, 0, clrBlue)) {
                            Print("Order modified successfully. SL: ", stopLossPrice, ", TP: ", takeProfitPrice);

                            // Update initial SL and TP
                            initialStopLoss = stopLossPrice;
                            initialTakeProfit = takeProfitPrice;
                        } else {
                            Print("Error modifying order: ", GetLastError());
                        }
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Display Round Numbers                                            |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Display Round Numbers (Updated)                                  |
//+------------------------------------------------------------------+
void DisplayRoundNumbers()
{
    // ObjectsDeleteAll(); // Uncomment this line if you want to clear old objects

    double referencePrice; // Reference price for round numbers

    // Check if there are open orders
    if (OrdersTotal() > 0) {
        // Use the first open order's price as reference
        if (OrderSelect(0, SELECT_BY_POS, MODE_TRADES)) {
            referencePrice = OrderOpenPrice();
        }
    } else {
        // If no orders are open, use the current market price
        referencePrice = Bid; // You can also use Ask depending on your requirement
    }

    // Define the range for round numbers
    double minPrice = MathFloor(referencePrice - 5); // 5 dollars below reference price
    double maxPrice = MathCeil(referencePrice + 5);  // 5 dollars above reference price

    // Draw round numbers in the range
    for (double price = minPrice; price <= maxPrice; price++) {
        string objName = StringFormat("RoundNumber_%.2f", price);

        // Check if the object already exists
        if (ObjectFind(0, objName) == -1) {
            // Create the horizontal line
            if (ObjectCreate(0, objName, OBJ_HLINE, 0, 0, price)) {
                // Check if the price is a multiple of 5
                if (MathMod(price, 5) == 0) {
                    ObjectSetInteger(0, objName, OBJPROP_COLOR, clrBlue);  // Blue for multiples of 5
                    ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);       // Thicker line
                } else {
                    ObjectSetInteger(0, objName, OBJPROP_COLOR, clrLavender); // Lavender for $1 steps
                    ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);           // Normal line width
                }
                ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_DOT);       // Dotted line for all
            } else {
                Print("Failed to create round number object at ", price, ". Error: ", GetLastError());
            }
        }
    }

    Print("Round numbers displayed around reference price: ", referencePrice);
}


//+------------------------------------------------------------------+
//| Draw Round Numbers                                               |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Draw Round Numbers with $1 and $5 Markings                      |
//+------------------------------------------------------------------+
void DrawRoundNumbers(double stopLossPrice, double takeProfitPrice)
{
    double roundStep = 1.0; // Step size for grid (1 dollar)
    double startPrice = MathFloor(stopLossPrice - 2); // Start drawing from below SL
    double endPrice = MathCeil(takeProfitPrice + 2);  // End drawing above TP

    // Loop to create round numbers between startPrice and endPrice
    for (double price = startPrice; price <= endPrice; price += roundStep) {
        string objName = StringFormat("RoundNumber_%.2f", price);

        // Check if the object already exists
        if (ObjectFind(0, objName) == -1) {
            // Create the line
            if (ObjectCreate(0, objName, OBJ_HLINE, 0, 0, price)) {
                // Check if the price is a multiple of 5
                if (MathMod(price, 5) == 0) {
                    ObjectSetInteger(0, objName, OBJPROP_COLOR, clrBlue);  // Blue line for $5
                    ObjectSetInteger(0, objName, OBJPROP_WIDTH, 2);       // Thicker line
                } 
                // Normal grid line (1-dollar steps)
                else {
                    ObjectSetInteger(0, objName, OBJPROP_COLOR, clrGray); // Gray line for $1
                    ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);       // Normal line width
                }
                ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_DOT);   // Dotted line for all
            } else {
                Print("Failed to create line at ", price, ". Error: ", GetLastError());
            }
        }
    }
}





//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
bool alertTriggered = false; // Keeps track if the alert has been triggered

//+------------------------------------------------------------------+
//| Draw Stop Loss History                                           |
//+------------------------------------------------------------------+
void DrawStopLossHistory()
{
    // Input parameters
    int StopLossHistoryDays = 1;
    int MaxEvents = 5;

    // Get the current time and start time for history lookup
    datetime currentTime = TimeCurrent();
    datetime startTime = currentTime - StopLossHistoryDays * 86400; // Time to start searching

    // Initialize variables for display
    int yOffset = 20; // Vertical offset for text display
    int eventCount = 0;
    double totalLossAmount = 0.0; // Reset total loss amount
    int consecutiveStopLossCount = 0; // Reset counter for consecutive stop losses

    // Loop through all history orders
    for (int i = OrdersHistoryTotal() - 1; i >= 0 && eventCount < MaxEvents; i--) {
        if (OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) {
            // Check if the order is within the time range
            if (OrderCloseTime() >= startTime) {
                // Check if the stop loss was hit
                double stopLossPrice = OrderStopLoss();
                double closePrice = OrderClosePrice();
                double profit = OrderProfit(); // Profit of the order
                double swap = OrderSwap(); // Swap fees
                double commission = OrderCommission(); // Commission fees

                // Total amount of money affected
                double totalAmount = profit + swap + commission;

                if ((OrderType() == OP_BUY && closePrice <= stopLossPrice) ||
                    (OrderType() == OP_SELL && closePrice >= stopLossPrice))
                {
                    // Stop loss was hit, increment the counter
                    consecutiveStopLossCount++;
                    totalLossAmount += totalAmount; // Accumulate total loss

                    // Prepare text to display
                    string message = StringFormat("Stop Loss Hit: (Symbol: %s) at %s | %.2f $",
                                                  OrderSymbol(),
                                                  TimeToString(OrderCloseTime(), TIME_DATE | TIME_MINUTES),
                                                  totalAmount);

                    // Draw text on the chart
                    string objName = StringFormat("StopLoss_%d", eventCount);
                    ObjectCreate(0, objName, OBJ_LABEL, 0, 0, 0);
                    ObjectSetText(objName, message, 12, "Arial", clrWhite);
                    ObjectSet(objName, OBJPROP_XDISTANCE, 10);
                    ObjectSet(objName, OBJPROP_YDISTANCE, yOffset);

                    yOffset += 20; // Adjust vertical position for next line
                    eventCount++;

                    // Check if two consecutive stop losses occurred and alert has not been triggered
                    if (consecutiveStopLossCount >= 2 && !alertTriggered) {
                        Alert("WARNING: Two consecutive stop losses detected! Consider stopping trading.");
                        Print("WARNING: Two consecutive stop losses detected! Total Loss: ", totalLossAmount);
                        alertTriggered = true; // Set alert as triggered
                    }
                }
                else {
                    // Reset counter if stop loss not hit
                    consecutiveStopLossCount = 0;
                }
            }
        }
    }
}

void DisplayCloseAndHighLowLines()
{
    // Calculate the time of 23:00 from the previous day
    datetime today = TimeCurrent();
    datetime previousDayStart = iTime(Symbol(), PERIOD_D1, 1); // Start of the previous day
    datetime time23 = previousDayStart + 23 * 3600;           // 23:00 of the previous day

    // Find the close price of the 23:00 candle in the M1 timeframe
    int index23 = iBarShift(Symbol(), PERIOD_M1, time23, true);
    if (index23 < 0) {
        Print("Error: Unable to find the 23:00 candle from the previous day.");
    } else {
        double closePrice23 = iClose(Symbol(), PERIOD_M1, index23);

        // Draw a horizontal line for the close price at 23:00
        string closeLineName = "Close23PreviousDay";
        if (ObjectFind(0, closeLineName) == -1) {
            if (ObjectCreate(0, closeLineName, OBJ_HLINE, 0, 0, closePrice23)) {
                ObjectSetInteger(0, closeLineName, OBJPROP_COLOR, clrWhite); // White line
                ObjectSetInteger(0, closeLineName, OBJPROP_WIDTH, 2);        // Solid line
            } else {
                Print("Failed to create line for close price at 23:00. Error: ", GetLastError());
            }
        }
    }

    // Calculate High and Low of the previous day
    double previousDayHigh = iHigh(Symbol(), PERIOD_D1, 1);
    double previousDayLow = iLow(Symbol(), PERIOD_D1, 1);

    // Draw High line for the previous day
    string highLinePrevious = "HighPreviousDay";
    if (ObjectFind(0, highLinePrevious) == -1) {
        if (ObjectCreate(0, highLinePrevious, OBJ_HLINE, 0, 0, previousDayHigh)) {
            ObjectSetInteger(0, highLinePrevious, OBJPROP_COLOR, clrGreen); // Dark green for high
            ObjectSetInteger(0, highLinePrevious, OBJPROP_WIDTH, 2);
            ObjectSetInteger(0, highLinePrevious, OBJPROP_STYLE, STYLE_SOLID);
        }
    }

    // Draw Low line for the previous day
    string lowLinePrevious = "LowPreviousDay";
    if (ObjectFind(0, lowLinePrevious) == -1) {
        if (ObjectCreate(0, lowLinePrevious, OBJ_HLINE, 0, 0, previousDayLow)) {
            ObjectSetInteger(0, lowLinePrevious, OBJPROP_COLOR, clrRed); // Dark red for low
            ObjectSetInteger(0, lowLinePrevious, OBJPROP_WIDTH, 2);
            ObjectSetInteger(0, lowLinePrevious, OBJPROP_STYLE, STYLE_SOLID);
        }
    }

    // Calculate High and Low of today
    double todayHigh = iHigh(Symbol(), PERIOD_D1, 0);
    double todayLow = iLow(Symbol(), PERIOD_D1, 0);

    // Draw High line for today
    string highLineToday = "HighToday";
    if (ObjectFind(0, highLineToday) == -1) {
        if (ObjectCreate(0, highLineToday, OBJ_HLINE, 0, 0, todayHigh)) {
            ObjectSetInteger(0, highLineToday, OBJPROP_COLOR, clrDarkGreen); // Dark green for high
            ObjectSetInteger(0, highLineToday, OBJPROP_WIDTH, 2);
            ObjectSetInteger(0, highLineToday, OBJPROP_STYLE, STYLE_SOLID);
        }
    }

    // Draw Low line for today
    string lowLineToday = "LowToday";
    if (ObjectFind(0, lowLineToday) == -1) {
        if (ObjectCreate(0, lowLineToday, OBJ_HLINE, 0, 0, todayLow)) {
            ObjectSetInteger(0, lowLineToday, OBJPROP_COLOR, clrMaroon); // Dark red for low
            ObjectSetInteger(0, lowLineToday, OBJPROP_WIDTH, 2);
            ObjectSetInteger(0, lowLineToday, OBJPROP_STYLE, STYLE_SOLID);
        }
    }
}



void DrawHalfHourLinesToday()
{
    // Remove previous half-hour lines
    for (int i = ObjectsTotal() - 1; i >= 0; i--) {
        string name = ObjectName(i);
        if (StringFind(name, "HalfHourLine_") == 0) {
            ObjectDelete(name);
        }
    }

    // Get the start time of the current day
    datetime todayStart = iTime(Symbol(), PERIOD_D1, 0); // Start of the current day
    datetime currentTime = TimeCurrent();               // Current time

    // Find the first half-hour mark within today
    datetime startTime = todayStart - (todayStart % 1800) + 1800; // Align to the next 30-minute mark

    // Draw lines for each half-hour mark within today
    for (datetime time = startTime; time <= currentTime; time += 1800) { // 1800 seconds = 30 minutes
        string lineName = StringFormat("HalfHourLine_%d", time);
        if (ObjectFind(0, lineName) == -1) {
            if (ObjectCreate(0, lineName, OBJ_VLINE, 0, time, 0)) {
                ObjectSetInteger(0, lineName, OBJPROP_COLOR, clrDarkGreen);   // Dark green for half-hour lines
                ObjectSetInteger(0, lineName, OBJPROP_STYLE, STYLE_DOT);     // Dotted line style
                ObjectSetInteger(0, lineName, OBJPROP_WIDTH, 1);             // Normal line width
            } else {
                Print("Failed to create half-hour line at ", time, ". Error: ", GetLastError());
            }
        }
    }

    Print("Half-hour lines for today drawn between ", TimeToString(todayStart, TIME_DATE | TIME_MINUTES),
          " and ", TimeToString(currentTime, TIME_DATE | TIME_MINUTES));
}




void DrawTodayOpenLine()
{
    // Get the Open price of today
    double todayOpen = iOpen(Symbol(), PERIOD_D1, 0);

    // Define a unique name for the line
    string openLineName = "TodayOpenLine";

    // Check if the line already exists
    if (ObjectFind(0, openLineName) == -1) {
        // Create a horizontal line at today's Open price
        if (ObjectCreate(0, openLineName, OBJ_HLINE, 0, 0, todayOpen)) {
            ObjectSetInteger(0, openLineName, OBJPROP_COLOR, clrYellow); // Set line color to Yellow
            ObjectSetInteger(0, openLineName, OBJPROP_WIDTH, 2);        // Set line width
            ObjectSetInteger(0, openLineName, OBJPROP_STYLE, STYLE_SOLID); // Set line style to solid
            Print("Today Open price line drawn: ", todayOpen);
        } else {
            Print("Failed to create Today Open line. Error: ", GetLastError());
        }
    } else {
        Print("Today Open line already exists.");
    }
}