%%
% fuzzy_stock_trader_main.m
%
% Description:
%    Implements "A Fuzzy Approach to Stock Market Timing" by Dong & Wang
%    using triangular MFs, sum-min inference and CoG defuzzification. 
%    A variety of stocks are run through the fuzzy engine.
%    
%%
clear all; close all; clc;

%% =======================================================================
%  Import historical stock price data
%  =======================================================================
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
TESLA = yahoo_import('yahoo_price_data/TSLA.csv');
APPLE = yahoo_import('yahoo_price_data/AAPL.csv');

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
legend('VANKE','GREE','PUDONG','XINJI','GOLDWIND');

% bonus plot of Tesla & APPLE prices
figure;
plot(TESLA.Date,TESLA.Close,'LineWidth',2);

%% =======================================================================
%  Simulate buying/selling stock w/ Fuzzy Engine Recomendations
%  =======================================================================
% start w/ $10,000 and simulate two scenarios:
%    #1: Spend all $10,000 on shares (Buy and Hold)
%    #2: Put stock data in and listen to the Fuzzy Engine -
%        If the threshold is exceeded, buy 500 shares
%        If 2*threshold is exceeded, spend all remaining money on shares
%        If -1*threshold is exceeded, buy 500 shares
%        If -2*threshold is exceeded, sell all shares

numStocks = 5;
stockList = struct();
stockList(1).stock = VANKE;
stockList(2).stock = GREE;
stockList(3).stock = PUDONG;
stockList(4).stock = XINJI;
stockList(5).stock = GOLDWIND;

verbose_flag = 0; % set to 1 to get day by day stock trading info printed

% create an empty stuct w/ fields for the results for each stock simulation
% expressed as the final value of the portfolio and the overall % gain
resultsStruct = struct();
for ii=1:numStocks
    resultsStruct(ii).buyholdvalue = 0;
    resultsStruct(ii).buyholdgain = 0;
    resultsStruct(ii).fuzzyvalue = 0;
    resultsStruct(ii).fuzzygain = 0;
end

for stockidx = 1:numStocks
    
    fprintf('=========================================================\n');
    fprintf('Simulating Stock #%d\n',stockidx);
    stock = stockList(stockidx).stock;
    
    % Set up buy/hold investor
    % Get starting share price and intial portfolio value
    stock_price = stock.Close(1);
    seed_cash = 10000;
    numshares = floor(seed_cash/stock_price);
    buy_hold_initial_value = numshares*stock_price;

    % Set up fuzzy investor
    % fuzzy investor will buy/sell in 500 share chunks
    share_increments = 500;  

    % run chosen stock through fuzzy engine
    % input stock, engine flag (0 for homemade fuzzy engine), plot flag (0 for
    % no plots)
    plot_flag = 0;
    if stockidx == 1
        plot_flag = 1; % only plot fuzzy engine plots once
    end
    defuzz_signal = fuzzy_stock_engine(stock, 0, plot_flag);
    numDays = length(defuzz_signal);
    fuzzy_warchest = seed_cash;
    fuzzy_sharecount = 0;
    thres = .5; % set the threshold for when to listen to the buy/sell signal

    % for each day in the simulation, extract the fuzzy engine's
    % recommendation and either buy, sell or hold
    for i=1:numDays
        if verbose_flag == 1
            fprintf('=========================================================\n');
            fprintf('Day %d\n',i);
        end
        stock_price = stock.Close(i);
        signal = defuzz_signal(i);
        
        % buy signal detected
        if signal >= -1*thres
            if signal >= -2*thres
                % strong buy -> buy with everything we have!
                if verbose_flag == 1
                    fprintf('Buying as many shares as possible\n');
                end
                n = floor(fuzzy_warchest/stock_price);
                bill = n*stock_price;
                if n == 0
                    if verbose_flag == 1
                        fprintf('Not enough cash to fulfill order\n');
                    end
                else
                    if verbose_flag == 1
                        fprintf('Spending remaining funds on %d shares\n',n);
                    end
                    fuzzy_warchest = fuzzy_warchest - bill;
                    fuzzy_sharecount = fuzzy_sharecount + n;
                end

            else
                % weak buy -> buy an incremental amount of shares!
                if verbose_flag == 1
                    fprintf('Buying %d shares on %s\n',share_increments,stock.Date(i));
                end
                bill = share_increments*stock_price;
                if bill > fuzzy_warchest
                    n = floor(fuzzy_warchest/stock_price);
                    if n ~= 0
                        if verbose_flag == 1
                            fprintf('Spending remaining funds on %d shares\n',n);
                        end
                        bill = n*stock_price;
                        fuzzy_warchest = fuzzy_warchest - bill;
                        fuzzy_sharecount = fuzzy_sharecount + n;
                    else
                        if verbose_flag == 1
                            fprintf('Not enough cash to fulfill order\n');
                        end
                    end
                else
                    fuzzy_warchest = fuzzy_warchest - bill;
                    fuzzy_sharecount = fuzzy_sharecount + share_increments;
                end
            end

        elseif signal <= 1*thres
            if signal <= 2*thres
                % strong sell -> sell everything we have!
                if verbose_flag == 1
                    fprintf('Selling %d remaining shares\n',fuzzy_sharecount);
                end
                proceeds = fuzzy_sharecount*stock_price;
                fuzzy_warchest = fuzzy_warchest + proceeds;
                fuzzy_sharecount = 0;
            else
                % weak sell -> sell incremental amount of shares!
                if verbose_flag == 1
                    fprintf('Selling %d shares on %s\n',share_increments,stock.Date(i));
                end
                if fuzzy_sharecount < share_increments
                    if fuzzy_sharecount == 0 
                        if verbose_flag == 1
                            fprintf('No more shares to sell\n');
                        end
                    else
                        if verbose_flag == 1
                            fprintf('Selling %d remaining shares\n',fuzzy_sharecount);
                        end
                        proceeds = fuzzy_sharecount*stock_price;
                        fuzzy_warchest = fuzzy_warchest + proceeds;
                        fuzzy_sharecount = 0;
                    end
                else
                    proceeds = share_increments*stock_price;
                    fuzzy_warchest = fuzzy_warchest + proceeds;
                    fuzzy_sharecount = fuzzy_sharecount - share_increments;
                end
            end
        else
            % hold!
            if verbose_flag == 1
                fprintf('Holding\n');
            end
        end
    end

    % Final day - tally up the results
    fprintf('=========================================================\n');
    fprintf('Starting stock price $%.2f on %s\n',stock.Close(1),stock.Date(1));
    fprintf('Ending stock price $%.2f on %s\n',stock.Close(end),stock.Date(end));
    
    % buy and hold results
    stock_price = stock.Close(end);
    buy_hold_final_value = numshares*stock_price; 
    bhp = (buy_hold_final_value/buy_hold_initial_value)*100;
    resultsStruct(stockidx).buyholdvalue = buy_hold_final_value;
    resultsStruct(stockidx).buyholdgain = bhp;
    fprintf('Buy and Hold Return %.2f%% \n',bhp);

    % fuzzy results
    % add together any cash on hand and the value of the remaining shares
    fuzzy_final_value = fuzzy_warchest + fuzzy_sharecount*stock_price;
    fp = (fuzzy_final_value/seed_cash)*100;
    resultsStruct(stockidx).fuzzyvalue = fuzzy_final_value;
    resultsStruct(stockidx).fuzzygain = fp;
    fprintf('Fuzzy Return %.2f%% \n',fp);

end