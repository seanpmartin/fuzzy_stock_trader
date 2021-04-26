% IF an upward breakout with large volum happends

% The difference between the exchange volume at the ith day and the 15 days
% moving average is calculated w/ the 10 day moving average (MA10)
% D_Max is the days from a local maximum (200 days moving window)
% D_Min is the days from a local minimum (200 days moving window)
% bob(i) = 0.98^(D_Max(i))*(MA10-globalMax)/globalMax +
% 0.98^(D_Min(i))*(MA10(i)-globalMin)/globalMin
% bob(i) > 0.05 in a bullish market
% bob(i) < -0.05 in a bearish market

%clear all;
close all; clc;

%% import historical stock price data
% Sources:
% https://finance.yahoo.com/quote/000002.SZ?p=000002.SZ
% https://finance.yahoo.com/quote/000651.SZ?p=000651.SZ
% https://finance.yahoo.com/quote/600000.SS?p=600000.SS
% https://finance.yahoo.com/quote/601918.SS?p=601918.SS
% https://finance.yahoo.com/quote/002202.SZ?p=002202.SZ

VANKE = yahoo_import('yahoo_price_data/VANKE-000002.csv');
GREE = yahoo_import('yahoo_price_data/GREE-000651.csv');
PUDONG = yahoo_import('yahoo_price_data/PUDONG-600000.csv');
XINJI = yahoo_import('yahoo_price_data/XINJI-601918.csv');
GOLDWIND = yahoo_import('yahoo_price_data/GOLDWIND-002202.csv');

% plot the closing stock price over time
figure;
plot(VANKE.Date,VANKE.Close,'LineWidth',2);
hold on;
plot(GREE.Date,GREE.Close,'LineWidth',2);
hold on;
plot(PUDONG.Date,PUDONG.Close,'LineWidth',2);
hold on;
plot(XINJI.Date,XINJI.Close,'LineWidth',2);
hold on;
plot(GOLDWIND.Date,GOLDWIND.Close,'LineWidth',2);
hold on;
legend('VANKE','GREE','PUDONG','XINJI','GOLDWIND')

% define number of inputs N, liguistic values LV and rules P
N=2; LV=5; P=LV^N;
stock_struct = VANKE;

%% declare triangle MF functions
% center triangle
ctriang=@(x,P) max( min( (x-P(1))/(P(2)-P(1)),(P(3)-x)/(P(3)-P(2)) ),0 );
% open-left triangle
ltriang=@(x,P) max( min( 1,(P(3)-x)/(P(3)-P(2)) ),0 );
% open-right triangle
rtriang=@(x,P) max( min( (x-P(1))/(P(2)-P(1)),1 ),0 );

%% Plot Input MFs
y = length(stock_struct.Close);
xstart = -10;
xstop = 10;
x = [xstart:((xstop-xstart)/y):xstop];
x = x(1:y);

strongDownBreakout_MF = ltriang(x,[-15,-10,-5]);
weakDownBreakout_MF = ctriang(x,[-10,-5,0]);
oscillation_MF = ctriang(x,[-5,0,5]);
weakUpBreakout_MF = ctriang(x,[0,5,10]);
strongUpBreakout_MF = rtriang(x,[5,10,15]);

% combine all the short term price MFs for the fuzzy engine
short_term_price_inMFparams = [-15, -10, -5;
                             -10, -5, 0;
                             -5, 0, 5;
                             0, 5, 10;
                             5, 10, 15];
                         
short_term_price_inMF = zeros(5,length(x));
for ii=1:length(x)
    short_term_price_inMF(1,ii)=ltriang(x(ii),short_term_price_inMFparams(1,:)); 
    short_term_price_inMF(2,ii)=ctriang(x(ii),short_term_price_inMFparams(2,:)); 
    short_term_price_inMF(3,ii)=ctriang(x(ii),short_term_price_inMFparams(3,:));
    short_term_price_inMF(4,ii)=ctriang(x(ii),short_term_price_inMFparams(4,:));
    short_term_price_inMF(5,ii)=rtriang(x(ii),short_term_price_inMFparams(5,:));
end

figure;
plot(x,short_term_price_inMF(1,:),'LineWidth',2);
hold on;
plot(x,short_term_price_inMF(2,:),'LineWidth',2);
hold on;
plot(x,short_term_price_inMF(3,:),'LineWidth',2);
hold on;
plot(x,short_term_price_inMF(4,:),'LineWidth',2);
hold on;
plot(x,short_term_price_inMF(5,:),'LineWidth',2);
hold on;
legend('Strong Downward Breakout','Weak Downward Breakout',...
    'Oscillation','Weak Upward Breakout','Strong Upward Breakout');
title('Short Term Price Change MFs');

y = length(stock_struct.Close);
xstart = -30;
xstop = 30;
x = [xstart:((xstop-xstart)/y):xstop];
x = x(1:y);
verySmall_MF = ltriang(x,[-45,-30,-15]);
small_MF = ctriang(x,[-30,-15,0]);
normal_MF = ctriang(x,[-15,0,15]);
large_MF = ctriang(x,[0,15,30]);
veryLarge_MF = rtriang(x,[15,30,45]);

% combine all the volume MFs for the fuzzy engine
volume_inMFparams = [-45, -30, -15;
                   -30, -15, 0;
                   -15, 0, 15;
                   0, 15, 30;
                   15, 30, 45];
                         
volume_inMF = zeros(5,length(x));
for ii=1:length(x)
    volume_inMF(1,ii)=ltriang(x(ii),volume_inMFparams(1,:)); 
    volume_inMF(2,ii)=ctriang(x(ii),volume_inMFparams(2,:)); 
    volume_inMF(3,ii)=ctriang(x(ii),volume_inMFparams(3,:));
    volume_inMF(4,ii)=ctriang(x(ii),volume_inMFparams(4,:));
    volume_inMF(5,ii)=rtriang(x(ii),volume_inMFparams(5,:));
end

figure;
plot(x,volume_inMF(1,:),'LineWidth',2);
hold on;
plot(x,volume_inMF(2,:),'LineWidth',2);
hold on;
plot(x,volume_inMF(3,:),'LineWidth',2);
hold on;
plot(x,volume_inMF(4,:),'LineWidth',2);
hold on;
plot(x,volume_inMF(5,:),'LineWidth',2);
hold on;
legend('Very Small','Small','Normal','Large','Very Large');
title('Exchange Volume Change MFs');

y = length(stock_struct.Close);
xstart = -1;
xstop = 1;
x = [xstart:((xstop-xstart)/y):xstop];
x = x(1:y);
bearish_MF = ltriang(x,[-.1,-.05,0]);
neutral_MF = ctriang(x,[-.05,0,.05]);
bullish_MF = rtriang(x,[0,.05,.1]);

% combine all the long term price MFs for the fuzzy engine
long_term_price_inMFparams = [-.1, -.05, 0;
                            -.05, 0, .05;
                            0, .05, .1];
                         
long_term_price_inMF = zeros(3,length(x));
for ii=1:length(x)
    long_term_price_inMF(1,ii)=ltriang(x(ii),long_term_price_inMFparams(1,:)); 
    long_term_price_inMF(2,ii)=ctriang(x(ii),long_term_price_inMFparams(2,:)); 
    long_term_price_inMF(3,ii)=rtriang(x(ii),long_term_price_inMFparams(3,:));
end

figure;
plot(x,long_term_price_inMF(1,:),'LineWidth',2);
hold on;
plot(x,long_term_price_inMF(2,:),'LineWidth',2);
hold on;
plot(x,long_term_price_inMF(3,:),'LineWidth',2);
hold on;
legend('Bearish','Neutral','Bullish');
title('Long Term Price Change MFs');

%% Plot Output MFs

figure;
outMFparams = [-4, -2, 0;
               -2, 0, 2;
               0, 2, 4];
xstart = -3;
xstop = 3;
x = [xstart:((xstop-xstart)/y):xstop];           
outMF = zeros(3,length(x));
for ii=1:length(x)
    outMF(1,ii) = ltriang(x(ii),outMFparams(1,:));
    outMF(2,ii) = ctriang(x(ii),outMFparams(2,:));
    outMF(3,ii) = rtriang(x(ii),outMFparams(3,:));
end
plot(x,outMF(1,:),'LineWidth',2);
hold on;
plot(x,outMF(2,:),'LineWidth',2);
hold on;
plot(x,outMF(3,:),'LineWidth',2);
hold on;
legend('Sell','Hold','Buy');
title('Output  MFs');

%% Short term price trending

% If the stock price is 10% higher than the highest point in the interval
% then a strong upward breakout occurs
% If the stock price is 5% higher than the highest point in the interval
% then a weak upward breakout occurs
% If the stock price is 10% lower than the lowest point in the interval
% then a strong downward breakout occurs
% If the stock price is 5% lower than the lowest point in the interval
% then a weak downward breakout occurs

% oscillation interval for the ith day is between the minimum price and the
% maximum price in (i-18)th to (i-3)th day
stock_struct = VANKE;
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

%% Exchange Volume trending
% The difference between the exchange volume at the ith day and the 15 days
% moving average is calculated (and expressed as a percentage)
MA_length = 15;
stock_struct.Volume_MA15 = movavg(stock_struct.Volume,'simple',MA_length);
stock_struct.VolumeTrend = ((stock_struct.Volume - stock_struct.Volume_MA15)./stock_struct.Volume).*100;

%% Long Term price trending
% Long term history price data determines whether the market is 
% bullish, bearish or in common state.
% calculate 10 day moving average of the stock price
MA_length = 10;
stock_struct.Close_MA10 = movavg(stock_struct.Close,'simple',MA_length);

% 200 day moving window used to determine local price maximum and minimum
window_length = 200;
forget = 0.98;
D_Max = 1;  % days from a local maximum
D_Min = 1;  % days from a local minimum
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
bob_threshold = 0.05;

%% Rule Base


%% Sum-Min Inference w/ CoG Defuzzification
x = stock_struct.ShortTrend;
short_term_price_inMF = zeros(5,length(x));
for ii=1:length(x)
    short_term_price_inMF(1,ii)=ltriang(x(ii),short_term_price_inMFparams(1,:)); 
    short_term_price_inMF(2,ii)=ctriang(x(ii),short_term_price_inMFparams(2,:)); 
    short_term_price_inMF(3,ii)=ctriang(x(ii),short_term_price_inMFparams(3,:));
    short_term_price_inMF(4,ii)=ctriang(x(ii),short_term_price_inMFparams(4,:));
    short_term_price_inMF(5,ii)=rtriang(x(ii),short_term_price_inMFparams(5,:));
end

x = stock_struct.VolumeTrend;
volume_inMF = zeros(5,length(x));
for ii=1:length(x)
    volume_inMF(1,ii)=ltriang(x(ii),volume_inMFparams(1,:)); 
    volume_inMF(2,ii)=ctriang(x(ii),volume_inMFparams(2,:)); 
    volume_inMF(3,ii)=ctriang(x(ii),volume_inMFparams(3,:));
    volume_inMF(4,ii)=ctriang(x(ii),volume_inMFparams(4,:));
    volume_inMF(5,ii)=rtriang(x(ii),volume_inMFparams(5,:));
end

x = stock_struct.bob;
long_term_price_inMF = zeros(3,length(x));
for ii=1:length(x)
    long_term_price_inMF(1,ii)=ltriang(x(ii),long_term_price_inMFparams(1,:)); 
    long_term_price_inMF(2,ii)=ctriang(x(ii),long_term_price_inMFparams(2,:)); 
    long_term_price_inMF(3,ii)=ctriang(x(ii),long_term_price_inMFparams(3,:));
end

short_term_weight = zeros(5,numDays);
volume_weight = zeros(5,numDays);
long_term_weight = zeros(3,numDays);
numRules = 27;
rules = zeros(numRules,length(outMF(1,:)));
xstart = -3;
xstop = 3;
x = [xstart:((xstop-xstart)/y):xstop];

% keep a running record of each day's overall implied fuzzy set
OIFS = zeros(numDays,length(rules(1,:)));

defuzzout = zeros(1,numDays);

for i=1:numDays
    
    % Determine ON rules
    % Three input linguistic variables...
    
    % Short Term Price trending antecedant weights
    for j1=1:5
        short_term_weight(j1,i)=short_term_price_inMF(j1,i);
    end
    
    % Exchange Volume trending antecedant weights
    for j1=1:5
        volume_weight(j1,i)=volume_inMF(j1,i); 
    end
    
    % Long Term Price trending antecedant weights
    for j1=1:3
        long_term_weight(j1,i)=long_term_price_inMF(j1,i); 
    end
    
    % Determine rule weights individually using the antecedant weights
    % Certainty of the conclusion is based on the least certain component
    % of the premise
    
    % IF the market is bearish THEN sell (-2)
    rules(1,:) = min(long_term_weight(1,i),outMF(1,:));
    
    % IF the market is bullish THEN buy (2)
    rules(2,:) = min(long_term_weight(3,i),outMF(3,:));

    % IF the market is neutral AND 
    % Strong Downward Breakout AND Very Small Volume THEN sell (-2)
    least_certain_premise = min(long_term_weight(2,i), short_term_weight(1,i));
    least_certain_premise = min(least_certain_premise, volume_weight(1,i));
    rules(3,:) = min(least_certain_premise, outMF(1,:));
    
    % IF the market is neutral AND 
    % Strong Downward Breakout AND Small Volume THEN sell (-2)
    least_certain_premise = min(long_term_weight(2,i), short_term_weight(1,i));
    least_certain_premise = min(least_certain_premise, volume_weight(2,i));
    rules(4,:) = min(least_certain_premise, outMF(1,:));
    
    % IF the market is neutral AND 
    % Strong Downward Breakout AND Normal Volume THEN sell (-2)
    least_certain_premise = min(long_term_weight(2,i), short_term_weight(1,i));
    least_certain_premise = min(least_certain_premise, volume_weight(3,i));
    rules(5,:) = min(least_certain_premise, outMF(1,:));
    
    % IF the market is neutral AND
    % Strong Downward Breakout AND Large Volume THEN sell (-2)
    least_certain_premise = min(long_term_weight(2,i), short_term_weight(1,i));
    least_certain_premise = min(least_certain_premise, volume_weight(4,i));
    rules(6,:) = min(least_certain_premise, outMF(1,:));
    
    % IF the market is neutral AND
    % Strong Downward Breakout AND Very Large Volume THEN sell (-3)
    least_certain_premise = min(long_term_weight(2,i), short_term_weight(1,i));
    least_certain_premise = min(least_certain_premise, volume_weight(5,i));
    rules(7,:) = min(least_certain_premise, outMF(1,:));
    
    % IF the market is neutral AND
    % Weak Downward Breakout AND Very Small Volume THEN sell (-1)
    least_certain_premise = min(long_term_weight(2,i), short_term_weight(2,i));
    least_certain_premise = min(least_certain_premise, volume_weight(1,i));
    rules(8,:) = min(least_certain_premise, outMF(1,:));
    
    % IF the market is neutral AND
    % Weak Downward Breakout AND Small Volume THEN sell (-1)
    least_certain_premise = min(long_term_weight(2,i), short_term_weight(2,i));
    least_certain_premise = min(least_certain_premise, volume_weight(2,i));
    rules(9,:) = min(least_certain_premise, outMF(1,:));
    
    % IF the market is neutral AND
    % Weak Downward Breakout AND Normal Volume THEN sell (-1)
    least_certain_premise = min(long_term_weight(2,i), short_term_weight(2,i));
    least_certain_premise = min(least_certain_premise, volume_weight(3,i));
    rules(10,:) = min(least_certain_premise, outMF(1,:));
    
    % IF the market is neutral AND
    % Weak Downward Breakout AND Large Volume THEN sell (-1)
    least_certain_premise = min(long_term_weight(2,i), short_term_weight(2,i));
    least_certain_premise = min(least_certain_premise, volume_weight(4,i));
    rules(11,:) = min(least_certain_premise, outMF(1,:));
    
    % IF the market is neutral AND
    % Weak Downward Breakout AND Very Large Volume THEN sell (-2)
    least_certain_premise = min(long_term_weight(2,i), short_term_weight(2,i));
    least_certain_premise = min(least_certain_premise, volume_weight(5,i));
    rules(12,:) = min(least_certain_premise, outMF(1,:));
    
    % IF the market is neutral AND
    % Oscillation AND Very Small Volume THEN hold (0)
    least_certain_premise = min(long_term_weight(2,i), short_term_weight(3,i));
    least_certain_premise = min(least_certain_premise, volume_weight(1,i));
    rules(13,:) = min(least_certain_premise, outMF(2,:));
    
    % IF the market is neutral AND
    % Oscillation AND Small Volume THEN hold (0)
    least_certain_premise = min(long_term_weight(2,i), short_term_weight(3,i));
    least_certain_premise = min(least_certain_premise, volume_weight(2,i));
    rules(14,:) = min(least_certain_premise, outMF(2,:));
    
    % IF the market is neutral AND
    % Oscillation AND Normal Volume THEN hold (0)
    least_certain_premise = min(long_term_weight(2,i), short_term_weight(3,i));
    least_certain_premise = min(least_certain_premise, volume_weight(3,i));
    rules(15,:) = min(least_certain_premise, outMF(2,:));
    
    % IF the market is neutral AND
    % Oscillation AND Large Volume THEN hold (0)
    least_certain_premise = min(long_term_weight(2,i), short_term_weight(3,i));
    least_certain_premise = min(least_certain_premise, volume_weight(4,i));
    rules(16,:) = min(least_certain_premise, outMF(2,:));
    
    % IF the market is neutral AND
    % Oscillation AND Very Large Volume THEN hold (0)
    least_certain_premise = min(long_term_weight(2,i), short_term_weight(3,i));
    least_certain_premise = min(least_certain_premise, volume_weight(5,i));
    rules(17,:) = min(least_certain_premise, outMF(2,:));

    % IF the market is neutral AND
    % Weak Upward Breakout AND Very Small Volume THEN hold (0)
    least_certain_premise = min(long_term_weight(2,i), short_term_weight(4,i));
    least_certain_premise = min(least_certain_premise, volume_weight(1,i));
    rules(18,:) = min(least_certain_premise, outMF(2,:));
    
    % IF the market is neutral AND
    % Weak Upward Breakout AND Small Volume THEN hold (0)
    least_certain_premise = min(long_term_weight(2,i), short_term_weight(4,i));
    least_certain_premise = min(least_certain_premise, volume_weight(2,i));
    rules(19,:) = min(least_certain_premise, outMF(2,:));
    
    % IF the market is neutral AND
    % Weak Upward Breakout AND Normal Volume THEN buy (1)
    least_certain_premise = min(long_term_weight(2,i), short_term_weight(4,i));
    least_certain_premise = min(least_certain_premise, volume_weight(3,i));
    rules(20,:) = min(least_certain_premise, outMF(3,:));
    
    % IF the market is neutral AND
    % Weak Upward Breakout AND Large Volume THEN buy (1)
    least_certain_premise = min(long_term_weight(2,i), short_term_weight(4,i));
    least_certain_premise = min(least_certain_premise, volume_weight(4,i));
    rules(21,:) = min(least_certain_premise, outMF(3,:));
    
    % IF the market is neutral AND
    % Weak Upward Breakout AND Very Large Volume THEN buy (2)
    least_certain_premise = min(long_term_weight(2,i), short_term_weight(4,i));
    least_certain_premise = min(least_certain_premise, volume_weight(5,i));
    rules(22,:) = min(least_certain_premise, outMF(3,:));
    
    % IF the market is neutral AND
    % Strong Upward Breakout AND Very Small Volume THEN hold (0)
    least_certain_premise = min(long_term_weight(2,i), short_term_weight(5,i));
    least_certain_premise = min(least_certain_premise, volume_weight(1,i));
    rules(23,:) = min(least_certain_premise, outMF(2,:));
    
    % IF the market is neutral AND
    % Strong Upward Breakout AND Small Volume THEN hold (0)
    least_certain_premise = min(long_term_weight(2,i), short_term_weight(5,i));
    least_certain_premise = min(least_certain_premise, volume_weight(2,i));
    rules(24,:) = min(least_certain_premise, outMF(2,:));
    
    % IF the market is neutral AND
    % Strong Upward Breakout AND Normal Volume THEN buy (1)
    least_certain_premise = min(long_term_weight(2,i), short_term_weight(5,i));
    least_certain_premise = min(least_certain_premise, volume_weight(3,i));
    rules(25,:) = min(least_certain_premise, outMF(3,:));
    
    % IF the market is neutral AND
    % Strong Upward Breakout AND Large Volume THEN buy (2)
    least_certain_premise = min(long_term_weight(2,i), short_term_weight(5,i));
    least_certain_premise = min(least_certain_premise, volume_weight(4,i));
    rules(26,:) = min(least_certain_premise, outMF(3,:));
    
    % IF the market is neutral AND
    % Strong Upward Breakout AND Very Large Volume THEN buy (2)
    least_certain_premise = min(long_term_weight(2,i), short_term_weight(5,i));
    least_certain_premise = min(least_certain_premise, volume_weight(5,i));
    rules(27,:) = min(least_certain_premise, outMF(3,:));

    % Take the union of all the rule conclusions to get the OIFS
    % OIFS = zeros(1,length(rules(1,:)));
    for j1=1:numRules
        OIFS(i,:) = max(OIFS(i,:),rules(j1,:));
    end
    
    % CoA/CoG Defuzzification (TODO - double check this...)
    defuzzout(i) = sum(OIFS(i,:).*x)/sum(OIFS(i,:));
    if isnan(defuzzout(i))
        disp('NaN!!');
        %disp(sum(OIFS(i,:)));
        %disp(i)
        if stock_struct.bob(i) > bob_threshold
            defuzzout(i) = 2;
        elseif stock_struct.bob(i) < -1*bob_threshold
            defuzzout(i) = -2;
        end
    end
    if isnan(defuzzout(i))
        disp('missed one!')
    end
    
    % zero out the rules array for next loop
    rules = zeros(numRules,length(outMF(1,:)));

end

% now simulate buy/sell somehow