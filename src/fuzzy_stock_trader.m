% strong downward breakout
% weak downward breakout
% oscillation
% weak upward breakout
% strong upward breakout

% oscillation interval for the ith day is between the minimum price and the
% maximum price in (i-18)th to (i-3)th day

% If the stock price is 10% higher than the highest point in the interval
% then a strong upward breakout occurs

% If the stock price is 5% higher than the highest point in the interval
% then a weak upward breakout occurs

% If the stock price is 10% lower than the lowest point in the interval
% then a strong downward breakout occurs

% If the stock price is 5% lower than the lowest point in the interval
% then a weak downward breakout occurs

% The difference between the exchange volume at the ith day and the 15 days
% moving average is calculated w/ the 10 day moving average (MA10)
% D_Max is the days from a local maximum (200 days moving window)
% D_Min is the days from a local minimum (200 days moving window)
% bob(i) = 0.98^(D_Max(i))*(MA10-globalMax)/globalMax +
% 0.98^(D_Min(i))*(MA10(i)-globalMin)/globalMin
% bob(i) > 0.05 in a bullish market
% bob(i) < -0.05 in a bearish market

