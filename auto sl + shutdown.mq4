//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // تنظیم تایمر برای اجرا هر دقیقه
    EventSetTimer(60);
    Print("Combined nima Initialized.");
    //ChartSetInteger(0, CHART_SCALE, 0);           // Set chart scale (smallest possible value)
    //ChartSetInteger(0, CHART_WIDTH_IN_BARS, 1);   // Minimum number of bars visible (zoom all the way in)

    // Set chart properties

    ChartSetInteger(0, CHART_MODE, CHART_CANDLES);  // Set chart to candlestick
    ChartSetInteger(0, CHART_SHOW_GRID, false);     // Turn off grid
    ChartSetInteger(0, CHART_FOREGROUND, true);     // Enable foreground mode
    ChartSetInteger(0, CHART_COLOR_BACKGROUND, clrBlack);    // Background color
    ChartSetInteger(0, CHART_COLOR_FOREGROUND, clrWhite);    // Foreground color
    //ChartSetInteger(0, CHART_COLOR_BULL_CANDLE, clrLimeGreen); // Bull candle color
    //ChartSetInteger(0, CHART_COLOR_BEAR_CANDLE, clrGold);    // Bear candle color
    DisplayCloseAndHighLowLines();
    
    DetectPinBars(500, 2.0, 0.3, 5);//it's not detecting
    // draw half an hour chart
    DrawHalfHourLinesToday();
    /// today open
    DrawTodayOpenLine();
    DetectEngulfingBars(50);
    DrawTrendLines();
////
    CreateScaleFixButton(); // Create the button on initialization
    DetectSupportResistance(100);
    //DetectAndDrawMicroChannels(500, 2, 20);
    return(INIT_SUCCEEDED);
    
    
    
    
        // drawing 2300 of yesterday

}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    //ObjectsDeleteAll(); // Remove all chart objects
    EventKillTimer();
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
  
    if (IsTradingLocked()) {
        DetectAndCloseManualOrders(); // معاملات دستی را ببندید
        return; // از ادامه اجرا جلوگیری کنید
 }
  
  
  
    // Handle Stop Loss and Take Profit modifications
    UpdateSLTP();
    
    // Update Stop Loss history display
    //DrawStopLossHistory();
     // Display round numbers for all active orders
    DisplayRoundNumbers();
    

    
    /// swing points
    DisplaySwingPoints();
    /// counting stop loss
    //***************************
    
    
    DrawStopLossHistory(); // Initialize Stop Loss history display
    //************************
    
    
    DetectBreakouts(20);//
    DrawOpen1630Candle(); //draw 1630 open
    DrawTrendLines();// it draws trend line
    //CheckTrendLineBreaks();// it's not working yet
    DetectPinBars(100, 2.0, 0.5, 10);//it's not detecting
    CheckTrendLineBreaks();///not working yet
    DetectEngulfingBars(20);
    ClearChartAtEndOfDay();
    DetectSupportResistance(100);
}



void OnTimer()
{
Print("OnTimer is called at ", TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES | TIME_SECONDS));
DrawAndCheckTrendLines();

}
void DrawAndCheckTrendLines()
{
   int lookback = 50; // تعداد کندل‌هایی که بررسی می‌شوند
   int currentBar = 1; // کندل جاری (به جز کندل صفر)
   
   // پیدا کردن نقاط بالا و پایین برای رسم ترندلاین
   double high1 = 0, high2 = 0, low1 = 0, low2 = 0;
   datetime timeHigh1, timeHigh2, timeLow1, timeLow2;

   for (int i = currentBar; i < lookback; i++)
   {
      if (High[i] > high1)
      {
         high2 = high1;
         timeHigh2 = timeHigh1;
         high1 = High[i];
         timeHigh1 = Time[i];
      }
      if (Low[i] < low1 || low1 == 0)
      {
         low2 = low1;
         timeLow2 = timeLow1;
         low1 = Low[i];
         timeLow1 = Time[i];
      }
   }

   // رسم ترندلاین بالا
   string highTrendName = "HighTrend";
   if (ObjectFind(0, highTrendName) == -1)
   {
      ObjectCreate(0, highTrendName, OBJ_TREND, 0, timeHigh1, high1, timeHigh2, high2);
      ObjectSetInteger(0, highTrendName, OBJPROP_COLOR, clrRed);
   }
   else
   {
      ObjectMove(0, highTrendName, 0, timeHigh1, high1);
      ObjectMove(0, highTrendName, 1, timeHigh2, high2);
   }

   // رسم ترندلاین پایین
   string lowTrendName = "LowTrend";
   if (ObjectFind(0, lowTrendName) == -1)
   {
      ObjectCreate(0, lowTrendName, OBJ_TREND, 0, timeLow1, low1, timeLow2, low2);
      ObjectSetInteger(0, lowTrendName, OBJPROP_COLOR, clrBlue);
   }
   else
   {
      ObjectMove(0, lowTrendName, 0, timeLow1, low1);
      ObjectMove(0, lowTrendName, 1, timeLow2, low2);
   }

   // بررسی شکست‌ها
   CheckTrendBreak(highTrendName, clrYellow, true); // شکست رو به بالا
   CheckTrendBreak(lowTrendName, clrGreen, false); // شکست رو به پایین
}

//+------------------------------------------------------------------+
//| Function to check trendline break                                |
//+------------------------------------------------------------------+
void CheckTrendBreak(string trendName, color arrowColor, bool isHighTrend)
{
   if (ObjectFind(0, trendName) == -1) return;

   // دریافت نقاط ترندلاین
   datetime time1 = ObjectGetInteger(0, trendName, OBJPROP_TIME1);
   double price1 = ObjectGetDouble(0, trendName, OBJPROP_PRICE1);
   datetime time2 = ObjectGetInteger(0, trendName, OBJPROP_TIME2);
   double price2 = ObjectGetDouble(0, trendName, OBJPROP_PRICE2);

   if (time1 == 0 || time2 == 0) return;

   // محاسبه شیب و تقاطع
   double slope = (price2 - price1) / ((double)(time2 - time1));
   double intercept = price1 - slope * time1;

   // قیمت پیش‌بینی‌شده بر اساس ترندلاین
   double expectedPrice = slope * Time[1] + intercept;

   // بررسی شکست
   if ((isHighTrend && Close[1] > expectedPrice) || (!isHighTrend && Close[1] < expectedPrice))
   {
      string arrowName = trendName + "_Break_" + TimeToString(Time[1], TIME_DATE | TIME_MINUTES);
      if (ObjectFind(0, arrowName) == -1)
      {
         ObjectCreate(0, arrowName, OBJ_ARROW, 0, Time[1], Close[1]);
         ObjectSetInteger(0, arrowName, OBJPROP_COLOR, arrowColor);
         ObjectSetInteger(0, arrowName, OBJPROP_ARROWCODE, 233); // فلش
      }
   }
}

//+------------------------------------------------------------------+
//| Check if a trendline is broken                                   |
//+------------------------------------------------------------------+
void CheckTrendBreak(string trendName, color arrowColor)
{
   if (ObjectFind(trendName) == -1) return;
   
   datetime lineTime1 = ObjectGetInteger(0, trendName, OBJPROP_TIME1);
   double linePrice1 = ObjectGetDouble(0, trendName, OBJPROP_PRICE1);
   datetime lineTime2 = ObjectGetInteger(0, trendName, OBJPROP_TIME2);
   double linePrice2 = ObjectGetDouble(0, trendName, OBJPROP_PRICE2);
   
   if (lineTime1 == 0 || lineTime2 == 0) return;
   
   double slope = (linePrice2 - linePrice1) / (lineTime2 - lineTime1);
   double intercept = linePrice1 - slope * lineTime1;
   
   double expectedPrice = slope * Time[1] + intercept;
   
   if ((trendName == "HighTrend" && Close[1] > expectedPrice) ||
       (trendName == "LowTrend" && Close[1] < expectedPrice))
   {
      string arrowName = trendName + "_BreakArrow_" + TimeToString(Time[1], TIME_DATE | TIME_MINUTES);
      ObjectCreate(0, arrowName, OBJ_ARROW, 0, Time[1], Close[1]);
      ObjectSetInteger(0, arrowName, OBJPROP_COLOR, arrowColor);
      ObjectSetInteger(0, arrowName, OBJPROP_ARROWCODE, 233); // فلش به سمت پایین
   }
}




void CheckTrendLineBreaks()
{
    for (int i = ObjectsTotal() - 1; i >= 0; i--)
    {
        string objName = ObjectName(i);

        // بررسی نوع شیء: فقط خطوط ترند
        if (ObjectGetInteger(0, objName, OBJPROP_TYPE) == OBJ_TREND)
        {
            double price1 = ObjectGetDouble(0, objName, OBJPROP_PRICE1);
            double price2 = ObjectGetDouble(0, objName, OBJPROP_PRICE2);
            datetime time1 = ObjectGetInteger(0, objName, OBJPROP_TIME1);
            datetime time2 = ObjectGetInteger(0, objName, OBJPROP_TIME2);

            if (time1 == 0 || time2 == 0 || price1 == 0 || price2 == 0)
                continue; // صرف نظر از خطوط نامعتبر

            // بررسی 50 کندل قبلی
            for (int j = 1; j <= 50; j++)
            {
                datetime candleTime = Time[j]; // زمان کندل
                double candleClose = Close[j]; // قیمت کلوز کندل

                // محاسبه قیمت خط ترند در زمان کندل جاری
                double trendPrice = price1 + ((price2 - price1) / (time2 - time1)) * (candleTime - time1);

                // بررسی شکست خطوط ترند
                if (candleClose > trendPrice && StringFind(objName, "HighTrendline_") == 0)
                {
                    string markerName = "BreakHigh_" + objName + "_" + IntegerToString(j);
                    if (!ObjectCreate(0, markerName, OBJ_ARROW, 0, candleTime, candleClose))
                    {
                        Print("Error creating marker for High Trendline break: ", markerName);
                    }
                    else
                    {
                        ObjectSetInteger(0, markerName, OBJPROP_COLOR, clrGreen); // تنظیم رنگ
                        ObjectSetInteger(0, markerName, OBJPROP_WIDTH, 2);        // تنظیم عرض
                        ObjectSetInteger(0, markerName, OBJPROP_ARROWCODE, 233); // فلش بالا
                    }
                }
                else if (candleClose < trendPrice && StringFind(objName, "LowTrendline_") == 0)
                {
                      markerName = "BreakLow_" + objName + "_" + IntegerToString(j);
                    if (!ObjectCreate(0, markerName, OBJ_ARROW, 0, candleTime, candleClose))
                    {
                        Print("Error creating marker for Low Trendline break: ", markerName);
                    }
                    else
                    {
                        ObjectSetInteger(0, markerName, OBJPROP_COLOR, clrRed);  // تنظیم رنگ
                        ObjectSetInteger(0, markerName, OBJPROP_WIDTH, 2);       // تنظیم عرض
                        ObjectSetInteger(0, markerName, OBJPROP_ARROWCODE, 234); // فلش پایین
                    }
                }
            }
        }
    }
}



void DetectSupportResistance(int barsToCheck)
{
    if (!showImportantBars) return; //
    // اطمینان حاصل شود که تعداد کافی بار برای بررسی وجود دارد
    if (Bars < barsToCheck + 1)
    {
        //Print("تعداد کافی بار برای بررسی حمایت و مقاومت وجود ندارد.");
        return;
    }

    for (int i = 1; i < barsToCheck; i++)
    {
        // دریافت فراکتال‌های مربوط به بار جاری
        double upperFractal = iFractals(NULL, 0, MODE_UPPER, i);
        double lowerFractal = iFractals(NULL, 0, MODE_LOWER, i);

        // شناسایی و نمایش مقاومت با فلش قرمز
        if (upperFractal > 0)
        {
            string resistanceName = StringFormat("Resistance_%d", i);
            if (!ObjectCreate(0, resistanceName, OBJ_ARROW, 0, Time[i], High[i] + (7 * Point)))
            {
                PrintFormat("resistance was failed %d", i);
                continue;
            }
            ObjectSetInteger(0, resistanceName, OBJPROP_COLOR, clrRed);
            ObjectSetInteger(0, resistanceName, OBJPROP_ARROWCODE, 201); // کد فلش مقاومت
            ObjectSetInteger(0, resistanceName, OBJPROP_WIDTH, 2);
            
            //PrintFormat("مقاومت شناسایی شد در %s با قیمت %.5f", TimeToString(Time[i]), upperFractal);
        }

        // شناسایی و نمایش حمایت با فلش آبی
        if (lowerFractal > 0)
        {
            string supportName = StringFormat("Support_%d", i);
            if (!ObjectCreate(0, supportName, OBJ_ARROW, 0, Time[i], Low[i] - (4 * Point)))
            {
                PrintFormat("support was failed %d ", i);
                continue;
            }
            ObjectSetInteger(0, supportName, OBJPROP_COLOR, clrBlue);
            ObjectSetInteger(0, supportName, OBJPROP_ARROWCODE, 200); // کد فلش حمایت
            ObjectSetInteger(0, supportName, OBJPROP_WIDTH, 2);
            //PrintFormat("حمایت شناسایی شد در %s با قیمت %.5f", TimeToString(Time[i]), lowerFractal);
        }
    }
}




void DetectEngulfingBars(int barsToCheck)
 
{   if (!showImportantBars) return; //
    for (int i = 1; i < barsToCheck; i++)
    {
        double prevOpen = Open[i + 1];
        double prevClose = Close[i + 1];
        double prevHigh = High[i + 1];
        double prevLow = Low[i + 1];

        double currOpen = Open[i];
        double currClose = Close[i];
        double currHigh = High[i];
        double currLow = Low[i];

        // Detect Bullish Engulfing Pattern
        if (currOpen < prevClose && currClose > prevOpen && prevClose < prevOpen &&
            currHigh > prevHigh ) // Ensure current High > previous High and current Low < previous Low
        {
            string bullishName = StringFormat("BullishEngulfing_%d", i);
            ObjectCreate(0, bullishName, OBJ_ARROW, 0, Time[i], Low[i] - (2 * Point));
            ObjectSetInteger(0, bullishName, OBJPROP_COLOR, clrBlue);
            ObjectSetInteger(0, bullishName, OBJPROP_ARROWCODE, 233); // Use a suitable symbol
            ObjectSetInteger(0, bullishName, OBJPROP_WIDTH, 3);
            PrintFormat("Bullish Engulfing Pattern detected at %s", TimeToString(Time[i]));
        }

        // Detect Bearish Engulfing Pattern
        if (currOpen > prevClose && currClose < prevOpen && prevClose > prevOpen &&
            currLow < prevLow) // Ensure current High > previous High and current Low < previous Low
        {
            string bearishName = StringFormat("BearishEngulfing_%d", i);
            ObjectCreate(0, bearishName, OBJ_ARROW, 0, Time[i], High[i] + (2 * Point));
            ObjectSetInteger(0, bearishName, OBJPROP_COLOR, clrRed);
            ObjectSetInteger(0, bearishName, OBJPROP_ARROWCODE, 234); // Use a suitable symbol
            ObjectSetInteger(0, bearishName, OBJPROP_WIDTH, 3);
           // PrintFormat("Bearish Engulfing Pattern detected at %s", TimeToString(Time[i]));
        }
    }
}


void DetectPinBars(int barsToCheck, double noseBodyRatio, double noseWickRatio, double minCandleLength)
{
    if (!showImportantBars) return; //
    for (int i = 1; i < barsToCheck; i++) {
        double high = High[i];
        double low = Low[i];
        double open = Open[i];
        double close = Close[i];

        double body = MathAbs(open - close);
        double upperWick = high - MathMax(open, close);
        double lowerWick = MathMin(open, close) - low;
        double range = high - low;

        // Ignore small candles
        if (range < minCandleLength * _Point) continue;

        // Debugging information
        PrintFormat("Bar %d: Range: %.5f, Body: %.5f, Upper Wick: %.5f, Lower Wick: %.5f", i, range, body, upperWick, lowerWick);

        // Detect Bullish Pin Bar
        if (lowerWick > body * noseBodyRatio && lowerWick > range * noseWickRatio && upperWick < range * 0.3 && close > open) {
            //Print("Bullish Pin Bar detected at ", TimeToString(Time[i], TIME_DATE | TIME_MINUTES));
            string objName = StringFormat("BullishPinBar_%d", i);
            ObjectCreate(0, objName, OBJ_ARROW, 0, Time[i], low);
            ObjectSetInteger(0, objName, OBJPROP_COLOR, clrBlue);
            ObjectSetInteger(0, objName, OBJPROP_ARROWCODE, 170);
            ObjectSetInteger(0, objName, OBJPROP_WIDTH, 3); // ضخامت بیشتر

            //TriggerAlerts("Bullish Pin Bar", Time[i]);
        }

        // Detect Bearish Pin Bar
        if (upperWick > body * noseBodyRatio && upperWick > range * noseWickRatio && lowerWick < range * 0.3 && close < open) {
            //Print("Bearish Pin Bar detected at ", TimeToString(Time[i], TIME_DATE | TIME_MINUTES));
            objName = StringFormat("BearishPinBar_%d", i);
            ObjectCreate(0, objName, OBJ_ARROW, 0, Time[i], high);
            ObjectSetInteger(0, objName, OBJPROP_COLOR, clrRed);
            ObjectSetInteger(0, objName, OBJPROP_ARROWCODE,170 );
            ObjectSetInteger(0, objName, OBJPROP_WIDTH, 3); // ضخامت بیشتر
           // TriggerAlerts("Bearish Pin Bar", Time[i]);
        }
    }
}

void ClearChartAtEndOfDay()
{
    // Get the current time
    datetime currentTime = TimeCurrent();

    // Calculate today's 23:55 time
    datetime todayStart = iTime(Symbol(), PERIOD_D1, 0); // Start of the current day
    datetime endOfDay = todayStart + (23 * 3600) + (55 * 60); // 23:55

    // Check if current time is 23:55 or later
    if (currentTime >= endOfDay)
    {
        // Remove all objects from the chart
        ObjectsDeleteAll();
        Print("All objects cleared from the chart at the end of the day.");
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
            //Print("Bullish Breakout detected at price: ", currentPrice);
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
           //Print("Bearish Breakout detected at price: ", currentPrice);
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
           // Print("Error: Unable to find the 16:30 candle.");
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
                //Print("16:30 Open price line drawn: ", openPrice1630);
            } else {
                Print("Failed to create 16:30 Open line. Error: ", GetLastError());
            }
        } else {
           // Print("16:30 Open line already exists.");
        }
    } else {
        //Print("Current time is before 16:30.");
    }
}

bool showTrendLines = false;  // Toggle for trendlines

bool showImportantBars = false;  // Toggle for pinbars and engulifng and support ressitance

//+------------------------------------------------------------------+
//| Create buttons                                                  |
//+------------------------------------------------------------------+

bool showSwingPoints = false; // Global variable to toggle Swing Points
bool showLines = false; // Global variable to toggle Swing Points
void CreateScaleFixButton()
{
    string scaleFixButton = "ScaleFixButton";
    string swingPointButton = "SwingPointButton";
    string trendLineButton = "TrendLineButton";
    string importantBarButton="importantBarButton";
    string LineButton="LineButton";
    if (ObjectFind(0, LineButton) == -1) {
        ObjectCreate(0, LineButton, OBJ_BUTTON, 0, 0, 0);
        ObjectSetInteger(0, LineButton, OBJPROP_CORNER, 2);
        ObjectSetInteger(0, LineButton, OBJPROP_XDISTANCE, 10);
        ObjectSetInteger(0, LineButton, OBJPROP_YDISTANCE, 160);
        ObjectSetInteger(0, LineButton, OBJPROP_XSIZE, 120);
        ObjectSetInteger(0, LineButton, OBJPROP_YSIZE, 30);
        ObjectSetString(0, LineButton, OBJPROP_TEXT, "Toggle Lines Button");
        ObjectSetInteger(0, LineButton, OBJPROP_COLOR, clrBlack);
        ObjectSetInteger(0, LineButton, OBJPROP_STYLE, STYLE_SOLID);
    }
    if (ObjectFind(0, importantBarButton) == -1) {
        ObjectCreate(0, importantBarButton, OBJ_BUTTON, 0, 0, 0);
        ObjectSetInteger(0, importantBarButton, OBJPROP_CORNER, 2);
        ObjectSetInteger(0, importantBarButton, OBJPROP_XDISTANCE, 10);
        ObjectSetInteger(0, importantBarButton, OBJPROP_YDISTANCE, 130);
        ObjectSetInteger(0, importantBarButton, OBJPROP_XSIZE, 120);
        ObjectSetInteger(0, importantBarButton, OBJPROP_YSIZE, 30);
        ObjectSetString(0, importantBarButton, OBJPROP_TEXT, "Toggle important bars");
        ObjectSetInteger(0, importantBarButton, OBJPROP_COLOR, clrBlack);
        ObjectSetInteger(0, importantBarButton, OBJPROP_STYLE, STYLE_SOLID);
    }

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
            //Print("Scale Fix toggled. New state: ", scaleFixState ? "Enabled" : "Disabled");
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
         if (sparam == "importantBarButton") {
            showImportantBars = !showImportantBars;
            //Print(showImportantBars);
            newText = showImportantBars ? "Hide important Bars" : "Show important Bars";
            ObjectSetString(0, "importantBarButton", OBJPROP_TEXT, newText);
            if (!showImportantBars) {
               ClearimportantBars(); // Clear trendlines as well
            }
        }
                 if (sparam == "LineButton") {
            showLines = !showLines;
            //Print(showImportantBars);
            newText = showLines ? "Hide  Lines " : "Show Lines";
            ObjectSetString(0, "LineButton", OBJPROP_TEXT, newText);
            if (!showImportantBars) {
               ClearLine(); // Clear trendlines as well
            }
        }        
        
              
        
        
        
        
    }
}
//+------------------------------------------------------------------+
//| Clear Trendlines                                                 |
//+------------------------------------------------------------------+
void ClearLine()
{
    for (int i = ObjectsTotal() - 1; i >= 0; i--) {
        string objName = ObjectName(i);

        // Delete only trendlines
        if (StringFind(objName, "RoundNumber_") == 0 ) {
            ObjectDelete(objName);
        }
    }
    //Print("All Trendlines cleared.");
}
void ClearTrendLines()
{
    for (int i = ObjectsTotal() - 1; i >= 0; i--) {
        string objName = ObjectName(i);

        // Delete only trendlines
        if (StringFind(objName, "HighTrendline_") == 0 || StringFind(objName, "LowTrendline_") == 0) {
            ObjectDelete(objName);
        }
    }
    //Print("All Trendlines cleared.");
}


void ClearSwingPoints()
{
    // Loop through all objects on the chart
    for (int i = ObjectsTotal() - 1; i >= 0; i--) {
        string objName = ObjectName(i);

        // Delete objects related to swing points and trendlines
        if (StringFind(objName, "SwingPoint_") == 0 || StringFind(objName, "HighTrendline_") == 0 || StringFind(objName, "LowTrendline_") == 0
        ||StringFind(objName, "BearishEngulfing_") == 0 
        ||StringFind(objName, "BullishEngulfing_") == 0
        ||StringFind(objName, "BullishPinBar_") == 0
        ||StringFind(objName, "BearishPinBar_") == 0
        ||StringFind(objName, "Support_") == 0
        ||StringFind(objName, "Resistance_") == 0        
        


        ) {
            ObjectDelete(objName);
        }
    }

}
void ClearimportantBars()
{
    // Loop through all objects on the chart
    for (int i = ObjectsTotal() - 1; i >= 0; i--) {
        string objName = ObjectName(i);

        // Delete objects related to swing points and trendlines
        if ( StringFind(objName, "BearishEngulfing_") == 0 
        ||StringFind(objName, "BullishEngulfing_") == 0
        ||StringFind(objName, "BullishPinBar_") == 0
        ||StringFind(objName, "BearishPinBar_") == 0
        ||StringFind(objName, "Support_") == 0
        ||StringFind(objName, "Resistance_") == 0        
        


        ) {
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

   // Print("Swing points detected and displayed.");
}

//+------------------------------------------------------------------+
//| Draw Trendlines                                                  |
//+------------------------------------------------------------------+
void DrawTrendLines()
{
    if (!showTrendLines) return; // Only proceed if toggle is enabled

    int barsToCheck = 50; // Number of bars to analyze
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
// تعریف آرایه برای ذخیره سفارش‌های تنظیم‌شده
int updatedOrders[500];  // حداکثر 500 سفارش
int updatedOrderCount = 0; // تعداد سفارش‌های تنظیم‌شده

// تابع برای بررسی اینکه آیا سفارش تنظیم شده است یا خیر
bool IsOrderUpdated(int ticket) {
    for (int i = 0; i < updatedOrderCount; i++) {
        if (updatedOrders[i] == ticket) {
            return true; // این سفارش قبلاً تنظیم شده است
        }
    }
    return false;
}

// تابع برای علامت‌گذاری سفارش به‌عنوان تنظیم‌شده
void MarkOrderAsUpdated(int ticket) {
    if (!IsOrderUpdated(ticket)) {
        updatedOrders[updatedOrderCount] = ticket;
        updatedOrderCount++;
    }
}

// تابع اصلی برای تنظیم SL و TP
void UpdateSLTP() {
    int minStopLevel = MarketInfo(Symbol(), MODE_STOPLEVEL);
    double point = MarketInfo(Symbol(), MODE_POINT);
    double stopLevel = minStopLevel * point;

    for (int i = 0; i < OrdersTotal(); i++) {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            // فقط معاملات خرید و فروش را بررسی کن
            if (OrderType() == OP_BUY || OrderType() == OP_SELL) {
                int ticket = OrderTicket();  // شماره سفارش
                double entryPrice = OrderOpenPrice();  // قیمت باز شدن
                double fractionalPart = NormalizeDouble(entryPrice - MathFloor(entryPrice), 5);
                double stopLossPrice = 0;
                double takeProfitPrice = 0;

                // بررسی اینکه آیا سفارش قبلاً تنظیم شده است یا نه
                if (IsOrderUpdated(ticket)) {
                    //Print("Order already updated. Skipping Order ", ticket);
                    continue;
                }

                // محاسبه SL و TP بر اساس نوع معامله
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

                // بررسی اینکه آیا SL و TP در محدوده حداقل هستند
                if (MathAbs(entryPrice - stopLossPrice) >= stopLevel &&
                    MathAbs(entryPrice - takeProfitPrice) >= stopLevel)
                {
                    // اصلاح سفارش
                    if (OrderModify(ticket, OrderOpenPrice(), stopLossPrice, takeProfitPrice, 0, clrBlue)) {
                        //Print("Order modified successfully. Ticket: ", ticket, ", SL: ", stopLossPrice, ", TP: ", takeProfitPrice);
                        MarkOrderAsUpdated(ticket);  // سفارش را به لیست اضافه کن
                    } else {
                        Print("Error modifying order: ", GetLastError());
                    }
                } else {
                    //Print("SL/TP levels do not meet minimum stop level requirements for Order ", ticket);
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
    //if (!showLines) return; 
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
                    ObjectSetInteger(0, objName, OBJPROP_BACK, false);    // تنظیم به عنوان بک‌گراند
                } else {
                    ObjectSetInteger(0, objName, OBJPROP_COLOR, clrLavender); // Lavender for $1 steps
                    ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);  
                    ObjectSetInteger(0, objName, OBJPROP_BACK, false);    // تنظیم به عنوان بک‌گراند         // Normal line width
                }
                ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_DOT);       // Dotted line for all
            } else {
                Print("Failed to create round number object at ", price, ". Error: ", GetLastError());
            }
        }
    }

   // Print("Round numbers displayed around reference price: ", referencePrice);
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
              //  Print("Failed to create line at ", price, ". Error: ", GetLastError());
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
    datetime alertTriggeredTime = 0; // متغیر برای ذخیره زمان هشدار

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

                    // Update alertTriggeredTime if this is the second consecutive stop loss
                    if (consecutiveStopLossCount == 2) {
                        alertTriggeredTime = OrderCloseTime(); // ذخیره زمان معامله‌ای که دومین استاپ متوالی است
                    }

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
                    if (consecutiveStopLossCount >= 3 && !alertTriggered) {
                        Alert("WARNING: Two consecutive stop losses detected! Consider stopping trading.");
                        Print("WARNING: Two consecutive stop losses detected! Total Loss: ", totalLossAmount);
                        Print("Time of alert triggered: ", TimeToString(alertTriggeredTime, TIME_DATE | TIME_MINUTES));
                        alertTriggered = true; // Set alert as triggered
                        
                        LockTrading(alertTriggeredTime, 30); // قفل معاملات برای 30 دقیقه با زمان هشدار

                        // Display a large message in the center of the screen
                        string warningMessage = "all trades will be closed from now ON ";
                        string warningObjName = "StopTradingWarning";

                        ObjectCreate(0, warningObjName, OBJ_LABEL, 0, 0, 0);
                        ObjectSetText(warningObjName, warningMessage, 50, "Arial Bold", clrRed); // Set size and color
                        ObjectSetInteger(0, warningObjName, OBJPROP_CORNER, CORNER_LEFT_UPPER); // Set corner
                        ObjectSetInteger(0, warningObjName, OBJPROP_XDISTANCE, 100); // Horizontal distance from corner
                        ObjectSetInteger(0, warningObjName, OBJPROP_YDISTANCE, 100); // Vertical distance from corner
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

//////*************************locking system 
void LockTrading(datetime lastStopTime, int minutes) {
    datetime lockUntil = lastStopTime + minutes * 60; // محاسبه زمان پایان قفل
    GlobalVariableSet("TradingLock", lockUntil); // ذخیره زمان در متغیر سراسری
    Print("Trading is locked until: ", TimeToString(lockUntil, TIME_DATE | TIME_MINUTES));
}
bool IsTradingLocked() {
    if (GlobalVariableCheck("TradingLock")) { // بررسی وجود متغیر قفل
        datetime lockUntil = GlobalVariableGet("TradingLock");
        if (TimeCurrent() < lockUntil) { // اگر هنوز زمان قفل باقی مانده است
            Print("Trading is locked. Lock expires at: ", TimeToString(lockUntil, TIME_DATE | TIME_MINUTES));
            return true;
        } else {
            GlobalVariableDel("TradingLock"); // اگر زمان قفل تمام شده، متغیر را حذف کن
        }
    }
    return false; // معاملات قفل نیستند
}

void DetectAndCloseManualOrders() {
    for (int i = OrdersTotal() - 1; i >= 0; i--) {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            if (OrderComment() == "") { // معامله دستی
                bool closed = OrderClose(OrderTicket(), OrderLots(), (OrderType() == OP_BUY ? Bid : Ask), 3, clrRed);
                if (closed) {
                    Print("Manual order closed. Ticket: ", OrderTicket());
                } else {
                    Print("Failed to close manual order. Error: ", GetLastError());
                }
            }
        }
    }
}

////////////////////**********************


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