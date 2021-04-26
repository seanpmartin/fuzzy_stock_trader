% create_stock_trends.m
%
% Description:
%    Takes stock data and creates trends detailed in "A Fuzzy Approach to 
%    Stock Market Timing" by Dong & Wang. Creates short term pricing, 
%    exchange volume, and long term pricing trend data
%    using triangular MFs, sum-min inference and CoG defuzzification
%
% Inputs:
%    stock_struct - Yahoo! Finance stock data (see yahoo_import.m)
%
% Outputs:
%    stock_struct - Yahoo! Finance stock data w/ columns for trending data
%
% Notes:
%
function stock_struct = create_stock_trends(stock_struct) 

%% =======================================================================
%  Short term price trending
%  =======================================================================
% Trend the short term price of the stock per the paper as stated below:
%
% If the stock price is 10% higher than the highest point in the interval
% then a strong upward breakout occurs
% If the stock price is 5% higher than the highest point in the interval
% then a weak upward breakout occurs
% If the stock price is 10% lower than the lowest point in the interval
% then a strong downward breakout occurs
% If the stock price is 5% lower than the lowest point in the interval
% then a weak downward breakout occurs

% Oscillation interval for the ith day is between the minimum price and the
% maximum price in (i-18)th to (i-3)th day

numDays = height(stock_struct);
lowerbound = 18;
upperbound = 3;
stock_struct.ShortTrend = zeros(numDays,1);
for i = 1+lowerbound:numDays
   % define oscillation interval which is the min price to max price
   % from startday until endday
   startday = i-lowerbound;
   endday = i-upperbound;
   oscinterval = stock_struct(startday:endday,:);
   highpoint = max(oscinterval.Close);
   lowpoint = min(oscinterval.Close);
   price = stock_struct.Close(i);
   
   % determine direction of the breakout and it's percentage
   if price > highpoint
       short_trend = ((price-highpoint)/highpoint)*100;
   elseif price < lowpoint
       short_trend = ((price-lowpoint)/lowpoint)*100;
   else
       short_trend = 0;
   end
   
   stock_struct.ShortTrend(i) = short_trend;
end

%% =======================================================================
%  Exchange Volume trending
%  =======================================================================
% Trend the exchange volume of the stock per the paper as stated below:
%
% The difference between the exchange volume at the ith day and the 15 days
% moving average is calculated (and expressed as a percentage)
%
MA_length = 15;
stock_struct.Volume_MA15 = movavg(stock_struct.Volume,'simple',MA_length);
stock_struct.VolumeTrend = ((stock_struct.Volume - stock_struct.Volume_MA15)./stock_struct.Volume).*100;
stock_struct(isinf(stock_struct.VolumeTrend),:)=[];

%% =======================================================================
%  Long Term price trending
%  =======================================================================
% Trend the long term price of the stock per the paper as stated below:
%
% Long term history price data determines whether the market is 
% bullish, bearish or in common state.
%
% Calculate 10 day moving average of the stock price
MA_length = 10;
stock_struct.Close_MA10 = movavg(stock_struct.Close,'simple',MA_length);

% 200 day moving window used to determine local price maximum and minimum
% D_Max = days from a local maximum
% D_Min = days from a local minimum
window_length = 200;
forget = 0.98;
numDays = height(stock_struct);

% need at least 2 days of data for this to work
for i=2:numDays
   
   % build moving window of prices 
   global_stock_window = stock_struct(1:i,:);
   global_max = max(global_stock_window.Close);
   global_min = min(global_stock_window.Close);
   if i<=200
       % currently do not have enough price data for a full 200 day 
       % moving window, so use all of the data we have
       stock_window = global_stock_window;
   else
       % use a 200 day moving window
       startday = i-window_length;
       endday = i;
       stock_window = global_stock_window(startday:endday,:);
   end
   
   % find local max/min in the window and the distance in days from today
   % to the local max/min
   [~,max_idx] = max(stock_window.Close);
   D_max = height(stock_window)-max_idx;
   [~,min_idx] = min(stock_window.Close);
   D_min = height(stock_window)-min_idx;
   
   % Determine Bullish or Bearish
   % bob is >0.05 in a Bull market
   % bob is <0.05 in a Bear market
   MA10 = stock_struct.Close_MA10(i);
   stock_struct.bob(i) = (forget^D_max)*((MA10-global_max)/global_max) ...
                         +(forget^D_min)*((MA10-global_min)/global_min);
end
end