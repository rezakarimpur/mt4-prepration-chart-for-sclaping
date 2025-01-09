Overview
This MQL4 Expert Advisor (EA) is designed for advanced chart visualization and trading management. It provides several functionalities, including automated adjustment of Stop Loss (SL) and Take Profit (TP), drawing historical and dynamic support/resistance levels, and enhancing the chart with custom visual indicators.

Key Features
Dynamic Stop Loss and Take Profit Adjustment (UpdateSLTP):

Automatically calculates and updates SL/TP levels for open trades based on price action logic.
Ensures the SL/TP levels respect the broker's minimum stop level.
Skips modification if SL/TP is manually changed by the user.
Historical Stop Loss Analysis (DrawStopLossHistory):

Displays information about the most recent stop-loss hits within a specified number of days.
Alerts the user if two consecutive stop-loss events occur.
Round Number Lines (DisplayRoundNumbers and DrawRoundNumbers):

Draws horizontal lines at round number levels.
Round numbers divisible by 5 are highlighted with blue lines, while other $1 steps are shown in gray or lavender.
Daily High and Low Levels (DisplayCloseAndHighLowLines):

Marks the high and low prices of the current day and the previous day.
Highs are displayed in dark green, and lows are displayed in dark red.
Specific Historical Price Levels (DisplayCloseAndHighLowLines):

Marks the close price of the 23:00 candle from the previous day.
Half-Hour Interval Lines (DrawHalfHourLinesToday):

Draws vertical dotted lines at every 30-minute interval for the current day.
Enhances intraday analysis with precise time markers.
Chart Customization (OnInit):

Automatically sets the chart to candlestick mode with specific background and foreground colors.
Grid lines are disabled for cleaner visuals.
How It Works
Initialization (OnInit):

Configures chart appearance upon initialization.
Invokes functions for drawing stop-loss history and other indicators.
Real-Time Updates (OnTick):

Continuously monitors open trades and adjusts SL/TP dynamically.
Updates chart elements, such as round numbers, daily high/low lines, and half-hour markers.
Deinitialization (OnDeinit):

Removes all chart objects and resets parameters when the EA is removed.
Usage
Attaching the EA:
Add the EA to any chart in MetaTrader 4.
Ensure sufficient historical data is available for M1 and D1 timeframes to enable all features.
Customization:
Adjust parameters like StopLossHistoryDays or visualization colors directly in the code.
Key Functions
UpdateSLTP:

Automatically modifies SL/TP based on logic specific to buy or sell trades.
DrawStopLossHistory:

Displays historical stop-loss hits as labels on the chart.
Triggers an alert if consecutive stop losses occur.
DisplayRoundNumbers & DrawRoundNumbers:

Draws round numbers with different styles for multiples of 5 and 1.
DisplayCloseAndHighLowLines:

Marks significant price levels, including the daily high/low and the previous day's 23:00 close.
DrawHalfHourLinesToday:

Adds vertical dotted lines for each 30-minute interval of the current day.
Visual Enhancements
Horizontal Lines:
Represent key price levels like round numbers, daily highs/lows, and historical closes.
Vertical Lines:
Mark half-hour intervals for the current day.
Example Output
Round Numbers:
Blue for $5 increments.
Gray/Lavender for $1 increments.
Daily High/Low:
Green for highs and red for lows.
Half-Hour Lines:
Dotted green lines at every 30-minute interval.
Prerequisites
Ensure the broker provides sufficient data for M1 and D1 timeframes.
SL/TP modification depends on the broker's minimum stop-level requirements.
Improvements
Add user-configurable input parameters for SL/TP logic, visualization colors, and alert thresholds.
Optimize performance for low-end systems by reducing redundant calculations in OnTick.
