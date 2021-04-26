%%
% fuzzy_stock_engine.m
%
% Description:
%    Implements "A Fuzzy Approach to Stock Market Timing" by Dong & Wang
%    using triangular MFs, sum-min inference and CoG defuzzification
%
% Inputs:
%    stock_struct - Yahoo! Finance stock data (see yahoo_import.m)
%    engine_flag  - Set to 0 to use homemade fuzzy inference engine
%                   Set to 1 to use MATLAB's built in fuzzy system toolbox
%    plot_flag    - Set to 0 to skip plots. Set to 1 to generate plots
%
% Outputs:
%    defuzzout - a crisp buy/sell signal based on stock data
%
% Notes:
%    The two engine types produce very similar results
%%
function defuzzout = fuzzy_stock_engine(stock_struct, engine_flag, plot_flag)

%% =======================================================================
%  Declare triangle MF functions
%  =======================================================================
% center triangle
ctriang=@(x,P) max( min( (x-P(1))/(P(2)-P(1)),(P(3)-x)/(P(3)-P(2)) ),0 );
% open-left triangle
ltriang=@(x,P) max( min( 1,(P(3)-x)/(P(3)-P(2)) ),0 );
% open-right triangle
rtriang=@(x,P) max( min( (x-P(1))/(P(2)-P(1)),1 ),0 );

%% =======================================================================
%  Create short term, volume, and long term trending data
%  =======================================================================
stock_struct = create_stock_trends(stock_struct);
numDays = height(stock_struct);
bob_threshold = 0.15;

if engine_flag == 0
    %% =======================================================================
    %  Homemade Fuzzy Engine
    %  =======================================================================

    % define number of inputs N, liguistic values LV and rules P
    N=2; LV=5; P=LV^N;

    %% =======================================================================
    %  Plot Input MFs
    %  =======================================================================
    y = length(stock_struct.Close);
    xstart = -10;
    xstop = 10;
    x = [xstart:((xstop-xstart)/y):xstop];
    x = x(1:y);

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

    if plot_flag == 1
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
        xlabel('Short Term Price Change (%)');
    end
    y = length(stock_struct.Close);
    xstart = -30;
    xstop = 30;
    x = [xstart:((xstop-xstart)/y):xstop];
    x = x(1:y);

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
    
    if plot_flag == 1
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
        xlabel('Exchange Volume Change (%)');
    end
    
    y = length(stock_struct.Close);
    xstart = -2*bob_threshold;
    xstop = 2*bob_threshold;
    x = [xstart:((xstop-xstart)/y):xstop];
    x = x(1:y);

    % combine all the long term price MFs for the fuzzy engine
    long_term_price_inMFparams = [-2*bob_threshold, -1*bob_threshold, 0;
                            -1*bob_threshold, 0, 1*bob_threshold;
                            0, 1*bob_threshold, 2*bob_threshold];

    long_term_price_inMF = zeros(3,length(x));
    for ii=1:length(x)
        long_term_price_inMF(1,ii)=ltriang(x(ii),long_term_price_inMFparams(1,:)); 
        long_term_price_inMF(2,ii)=ctriang(x(ii),long_term_price_inMFparams(2,:)); 
        long_term_price_inMF(3,ii)=rtriang(x(ii),long_term_price_inMFparams(3,:));
    end

    if plot_flag == 1
        figure;
        plot(x,long_term_price_inMF(1,:),'LineWidth',2);
        hold on;
        plot(x,long_term_price_inMF(2,:),'LineWidth',2);
        hold on;
        plot(x,long_term_price_inMF(3,:),'LineWidth',2);
        hold on;
        legend('Bearish','Neutral','Bullish');
        title('Long Term Price Change MFs');
        xlabel('Long Term Market Sentiment (bob)');
    end
    
    %% =======================================================================
    %  Plot Output MFs
    %  =======================================================================

    outMFparams = [-3, -2, -1;
                   -2, -1, 0;
                   -1, 0, 1;
                   0, 1, 2;
                   1, 2, 3];
    xstart = -3;
    xstop = 3;
    x = [xstart:((xstop-xstart)/y):xstop];           
    outMF = zeros(5,length(x));
    for ii=1:length(x)
        outMF(1,ii) = ltriang(x(ii),outMFparams(1,:));
        outMF(2,ii) = ctriang(x(ii),outMFparams(2,:));
        outMF(3,ii) = ctriang(x(ii),outMFparams(3,:));
        outMF(4,ii) = ctriang(x(ii),outMFparams(4,:));
        outMF(5,ii) = rtriang(x(ii),outMFparams(5,:));
    end
    
    if plot_flag == 1
        figure
        plot(x,outMF(1,:),'LineWidth',2);
        hold on;
        plot(x,outMF(2,:),'LineWidth',2);
        hold on;
        plot(x,outMF(3,:),'LineWidth',2);
        hold on;
        plot(x,outMF(4,:),'LineWidth',2);
        hold on;
        plot(x,outMF(5,:),'LineWidth',2);
        hold on;
        legend('Strong Sell','Weak Sell','Hold','Weak Buy','Strong Buy');
        title('Output  MFs');
        xlabel('Buy/Sell/Hold Signal Strength');
    end
    %% =======================================================================
    %  Sum-Min Inference w/ CoG Defuzzification
    %  =======================================================================
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
        long_term_price_inMF(3,ii)=rtriang(x(ii),long_term_price_inMFparams(3,:));
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
    
    % get a random day to plot the fuzzy inference process
    plotting_day = randi([30 numDays],1);
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
        rules(2,:) = min(long_term_weight(3,i),outMF(5,:));

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
        rules(8,:) = min(least_certain_premise, outMF(2,:));

        % IF the market is neutral AND
        % Weak Downward Breakout AND Small Volume THEN sell (-1)
        least_certain_premise = min(long_term_weight(2,i), short_term_weight(2,i));
        least_certain_premise = min(least_certain_premise, volume_weight(2,i));
        rules(9,:) = min(least_certain_premise, outMF(2,:));

        % IF the market is neutral AND
        % Weak Downward Breakout AND Normal Volume THEN sell (-1)
        least_certain_premise = min(long_term_weight(2,i), short_term_weight(2,i));
        least_certain_premise = min(least_certain_premise, volume_weight(3,i));
        rules(10,:) = min(least_certain_premise, outMF(2,:));

        % IF the market is neutral AND
        % Weak Downward Breakout AND Large Volume THEN sell (-1)
        least_certain_premise = min(long_term_weight(2,i), short_term_weight(2,i));
        least_certain_premise = min(least_certain_premise, volume_weight(4,i));
        rules(11,:) = min(least_certain_premise, outMF(2,:));

        % IF the market is neutral AND
        % Weak Downward Breakout AND Very Large Volume THEN sell (-2)
        least_certain_premise = min(long_term_weight(2,i), short_term_weight(2,i));
        least_certain_premise = min(least_certain_premise, volume_weight(5,i));
        rules(12,:) = min(least_certain_premise, outMF(1,:));

        % IF the market is neutral AND
        % Oscillation AND Very Small Volume THEN hold (0)
        least_certain_premise = min(long_term_weight(2,i), short_term_weight(3,i));
        least_certain_premise = min(least_certain_premise, volume_weight(1,i));
        rules(13,:) = min(least_certain_premise, outMF(3,:));

        % IF the market is neutral AND
        % Oscillation AND Small Volume THEN hold (0)
        least_certain_premise = min(long_term_weight(2,i), short_term_weight(3,i));
        least_certain_premise = min(least_certain_premise, volume_weight(2,i));
        rules(14,:) = min(least_certain_premise, outMF(3,:));

        % IF the market is neutral AND
        % Oscillation AND Normal Volume THEN hold (0)
        least_certain_premise = min(long_term_weight(2,i), short_term_weight(3,i));
        least_certain_premise = min(least_certain_premise, volume_weight(3,i));
        rules(15,:) = min(least_certain_premise, outMF(3,:));

        % IF the market is neutral AND
        % Oscillation AND Large Volume THEN hold (0)
        least_certain_premise = min(long_term_weight(2,i), short_term_weight(3,i));
        least_certain_premise = min(least_certain_premise, volume_weight(4,i));
        rules(16,:) = min(least_certain_premise, outMF(3,:));

        % IF the market is neutral AND
        % Oscillation AND Very Large Volume THEN hold (0)
        least_certain_premise = min(long_term_weight(2,i), short_term_weight(3,i));
        least_certain_premise = min(least_certain_premise, volume_weight(5,i));
        rules(17,:) = min(least_certain_premise, outMF(3,:));

        % IF the market is neutral AND
        % Weak Upward Breakout AND Very Small Volume THEN hold (0)
        least_certain_premise = min(long_term_weight(2,i), short_term_weight(4,i));
        least_certain_premise = min(least_certain_premise, volume_weight(1,i));
        rules(18,:) = min(least_certain_premise, outMF(3,:));

        % IF the market is neutral AND
        % Weak Upward Breakout AND Small Volume THEN hold (0)
        least_certain_premise = min(long_term_weight(2,i), short_term_weight(4,i));
        least_certain_premise = min(least_certain_premise, volume_weight(2,i));
        rules(19,:) = min(least_certain_premise, outMF(3,:));

        % IF the market is neutral AND
        % Weak Upward Breakout AND Normal Volume THEN buy (1)
        least_certain_premise = min(long_term_weight(2,i), short_term_weight(4,i));
        least_certain_premise = min(least_certain_premise, volume_weight(3,i));
        rules(20,:) = min(least_certain_premise, outMF(4,:));

        % IF the market is neutral AND
        % Weak Upward Breakout AND Large Volume THEN buy (1)
        least_certain_premise = min(long_term_weight(2,i), short_term_weight(4,i));
        least_certain_premise = min(least_certain_premise, volume_weight(4,i));
        rules(21,:) = min(least_certain_premise, outMF(4,:));

        % IF the market is neutral AND
        % Weak Upward Breakout AND Very Large Volume THEN buy (2)
        least_certain_premise = min(long_term_weight(2,i), short_term_weight(4,i));
        least_certain_premise = min(least_certain_premise, volume_weight(5,i));
        rules(22,:) = min(least_certain_premise, outMF(5,:));

        % IF the market is neutral AND
        % Strong Upward Breakout AND Very Small Volume THEN hold (0)
        least_certain_premise = min(long_term_weight(2,i), short_term_weight(5,i));
        least_certain_premise = min(least_certain_premise, volume_weight(1,i));
        rules(23,:) = min(least_certain_premise, outMF(3,:));

        % IF the market is neutral AND
        % Strong Upward Breakout AND Small Volume THEN hold (0)
        least_certain_premise = min(long_term_weight(2,i), short_term_weight(5,i));
        least_certain_premise = min(least_certain_premise, volume_weight(2,i));
        rules(24,:) = min(least_certain_premise, outMF(3,:));

        % IF the market is neutral AND
        % Strong Upward Breakout AND Normal Volume THEN buy (1)
        least_certain_premise = min(long_term_weight(2,i), short_term_weight(5,i));
        least_certain_premise = min(least_certain_premise, volume_weight(3,i));
        rules(25,:) = min(least_certain_premise, outMF(4,:));

        % IF the market is neutral AND
        % Strong Upward Breakout AND Large Volume THEN buy (2)
        least_certain_premise = min(long_term_weight(2,i), short_term_weight(5,i));
        least_certain_premise = min(least_certain_premise, volume_weight(4,i));
        rules(26,:) = min(least_certain_premise, outMF(5,:));

        % IF the market is neutral AND
        % Strong Upward Breakout AND Very Large Volume THEN buy (2)
        least_certain_premise = min(long_term_weight(2,i), short_term_weight(5,i));
        least_certain_premise = min(least_certain_premise, volume_weight(5,i));
        rules(27,:) = min(least_certain_premise, outMF(5,:));

        % Take the union of all the rule conclusions to get the OIFS
        % OIFS = zeros(1,length(rules(1,:)));
        for j1=1:numRules
            OIFS(i,:) = max(OIFS(i,:),rules(j1,:));
        end

        % CoA/CoG Defuzzification
        defuzzout(i) = sum(OIFS(i,:).*x)/sum(OIFS(i,:));
        if isnan(defuzzout(i))
            % get rid of any potential divide by zeros in the bob
            % calculation (this could also be done when bob is first
            % calculated...)
            if stock_struct.bob(i) > bob_threshold
                defuzzout(i) = 2;
            elseif stock_struct.bob(i) < -1*bob_threshold
                defuzzout(i) = -2;
            end
        end
        
        % plot the OIFS and defuzzified output as a line
        if plot_flag == 1
            if i == plotting_day
                x = [-3:6/y:3];
                figure;
                subplot(2,1,1);
                plot(x, OIFS(i,:),'LineWidth',2);
                xline(defuzzout(i),'-r','Signal','LineWidth',2);
                titleString = sprintf('Example Defuzzification on %s',stock_struct.Date(i));
                title(titleString);
                xlabel('Buy/Sell/Hold Signal Strength');
                subplot(2,1,2);
                plot(x,outMF(1,:),'LineWidth',2);
                hold on;
                plot(x,outMF(2,:),'LineWidth',2);
                hold on;
                plot(x,outMF(3,:),'LineWidth',2);
                hold on;
                plot(x,outMF(4,:),'LineWidth',2);
                hold on;
                plot(x,outMF(5,:),'LineWidth',2);
                hold on;
                legend('Strong Sell','Weak Sell','Hold','Weak Buy','Strong Buy');
                title('Output  MFs');
                xlabel('Buy/Sell/Hold Signal Strength');
                fprintf('Example Defuzz Plot Input Values:\n');
                fprintf('Short Term Price Trend %.4f%%\n',stock_struct.ShortTrend(i));
                fprintf('Exchange Volume Trend %.2f%%\n',stock_struct.VolumeTrend(i));
                fprintf('Long Term Price Trend bob %.2f\n',stock_struct.bob(i));
                fprintf('Defuzzified Recomendation: %d\n', defuzzout(i));
            end
        end

        % zero out the rules array for next loop
        rules = zeros(numRules,length(outMF(1,:)));
    
    end

else
    %% ===================================================================    
    %% Sum-Min Inference w/ CoG Defuzzification using MATLAB mamfis 
    % ====================================================================
    % for details see:
    % https://www.mathworks.com/help/fuzzy/working-from-the-command-line.html
    short_term_price_inMFparams = [-15, -10, -5;
                                   -10, -5, 0;
                                   -5, 0, 5;
                                   0, 5, 10;
                                   5, 10, 15];
    volume_inMFparams = [-45, -30, -15;
                         -30, -15, 0;
                         -15, 0, 15;
                         0, 15, 30;
                         15, 30, 45];
    long_term_price_inMFparams = [-.1, -.05, 0;
                                -.05, 0, .05;
                                0, .05, .1];
    outMFparams = [-3, -2, -1;
                   -2, -1, 0;
                   -1, 0, 1;
                   0, 1, 2;
                   1, 2, 3];
               
    fis = mamfis('Name',"Stock Trader");
    fis.AggregationMethod = 'sum';
    short_term_price_range = [min(stock_struct.ShortTrend),max(stock_struct.ShortTrend)];
    fis = addInput(fis,short_term_price_range,'Name',"Short Term Price");
    fis = addMF(fis,"Short Term Price","trimf",[-10000, -10, -5],'Name',"strong dw bo");
    fis = addMF(fis,"Short Term Price","trimf",short_term_price_inMFparams(2,:),'Name',"weak dw bo");
    fis = addMF(fis,"Short Term Price","trimf",short_term_price_inMFparams(3,:),'Name',"oscillation");
    fis = addMF(fis,"Short Term Price","trimf",short_term_price_inMFparams(4,:),'Name',"weak uw bo");
    fis = addMF(fis,"Short Term Price","trimf",[5, 10, 10000],'Name',"strong uw bo");

    volume_range = [min(stock_struct.VolumeTrend),max(stock_struct.VolumeTrend)];
    fis = addInput(fis,volume_range,'Name',"Volume");
    fis = addMF(fis,"Volume","trimf",[-10000, -30, -15],'Name',"very small");
    fis = addMF(fis,"Volume","trimf",volume_inMFparams(2,:),'Name',"small");
    fis = addMF(fis,"Volume","trimf",volume_inMFparams(3,:),'Name',"normal");
    fis = addMF(fis,"Volume","trimf",volume_inMFparams(4,:),'Name',"large");
    fis = addMF(fis,"Volume","trimf",[15, 30, 10000],'Name',"very large");

    long_term_price_range = [min(stock_struct.bob),max(stock_struct.bob)];
    fis = addInput(fis,long_term_price_range,'Name',"Long Term Price");
    fis = addMF(fis,"Long Term Price","trimf",[-10000, -.05, 0],'Name',"bearish");
    fis = addMF(fis,"Long Term Price","trimf",long_term_price_inMFparams(2,:),'Name',"neutral");
    fis = addMF(fis,"Long Term Price","trimf",[0, .05, 10000],'Name',"bullish");

    fis = addOutput(fis,[-3 3],'Name',"Action");
    fis = addMF(fis,"Action","trimf",[-10000, -2, -1],'Name',"strong sell"); % -2
    fis = addMF(fis,"Action","trimf",outMFparams(2,:),'Name',"weak sell"); % -1
    fis = addMF(fis,"Action","trimf",outMFparams(3,:),'Name',"hold"); % 0
    fis = addMF(fis,"Action","trimf",outMFparams(4,:),'Name',"weak buy"); % 1
    fis = addMF(fis,"Action","trimf",[1, 2, 10000],'Name',"strong buy"); % 2

    % IF the market is bearish THEN sell (-2)
    % IF the market is bullish THEN buy (2)
    % IF the market is neutral AND Strong Downward Breakout AND Very Small Volume THEN sell (-2)
    % IF the market is neutral AND Strong Downward Breakout AND Small Volume THEN sell (-2)
    % IF the market is neutral AND  Strong Downward Breakout AND Normal Volume THEN sell (-2)
    % IF the market is neutral AND Strong Downward Breakout AND Large Volume THEN sell (-2)
    % IF the market is neutral AND Strong Downward Breakout AND Very Large Volume THEN sell (-3)
    % IF the market is neutral AND Weak Downward Breakout AND Very Small Volume THEN sell (-1)
    % IF the market is neutral AND Weak Downward Breakout AND Small Volume THEN sell (-1)
    % IF the market is neutral AND Weak Downward Breakout AND Normal Volume THEN sell (-1)
    % IF the market is neutral AND Weak Downward Breakout AND Large Volume THEN sell (-1)
    % IF the market is neutral AND Weak Downward Breakout AND Very Large Volume THEN sell (-2)   
    % IF the market is neutral AND Oscillation AND Very Small Volume THEN hold (0)
    % IF the market is neutral AND Oscillation AND Small Volume THEN hold (0)   
    % IF the market is neutral AND Oscillation AND Normal Volume THEN hold (0)
    % IF the market is neutral AND Oscillation AND Large Volume THEN hold (0)
    % IF the market is neutral AND Oscillation AND Very Large Volume THEN hold (0)
    % IF the market is neutral AND Weak Upward Breakout AND Very Small Volume THEN hold (0) 
    % IF the market is neutral AND Weak Upward Breakout AND Small Volume THEN hold (0)  
    % IF the market is neutral AND Weak Upward Breakout AND Normal Volume THEN buy (1) 
    % IF the market is neutral AND Weak Upward Breakout AND Large Volume THEN buy (1)  
    % IF the market is neutral AND Weak Upward Breakout AND Very Large Volume THEN buy (2)
    % IF the market is neutral AND Strong Upward Breakout AND Very Small Volume THEN hold (0)
    % IF the market is neutral AND Strong Upward Breakout AND Small Volume THEN hold (0)
    % IF the market is neutral AND Strong Upward Breakout AND Normal Volume THEN buy (1)
    % IF the market is neutral AND Strong Upward Breakout AND Large Volume THEN buy (2)
    % IF the market is neutral AND Strong Upward Breakout AND Very Large Volume THEN buy (2)

    % Col 1 = input linguistic var1
    % Col 2 = input linguistic var2
    % Col 3 = input linguistic var3
    % Col 4 = output linguistic var
    % Col 5 = rule weight (0<=w<=1)
    % Col 6 = linguistic operation (1=AND, 2=OR)
    ruleList = [0 0 1 1 1 1;
                0 0 3 5 1 1;
                1 1 2 1 1 1;
                1 2 2 1 1 1;
                1 3 2 1 1 1;
                1 4 2 1 1 1;
                1 5 2 1 1 1;
                2 1 2 2 1 1;
                2 2 2 2 1 1;
                2 3 2 2 1 1;
                2 4 2 2 1 1;
                2 5 2 1 1 1;
                3 1 2 3 1 1;
                3 2 2 3 1 1;
                3 3 2 3 1 1;
                3 4 2 3 1 1;
                3 5 2 3 1 1;
                4 1 2 3 1 1;
                4 2 2 3 1 1;
                4 3 2 4 1 1;
                4 4 2 4 1 1;
                4 5 2 5 1 1;
                5 1 2 3 1 1;
                5 2 2 3 1 1;
                5 3 2 4 1 1;
                5 4 2 5 1 1;
                5 5 2 5 1 1];

    % Plot all MFs
    fis = addRule(fis,ruleList);
    
    if plot_flag == 1
        figure;
        plotmf(fis,'input',1,10000);
        xlim([-15,15]);
        figure;
        plotmf(fis,'input',2,10000);
        xlim([-35,35]);
        figure;
        plotmf(fis,'input',3,10000);
        xlim([-1*bob_threshold,bob_threshold]);
        figure;
        plotmf(fis,'output',1);
    end
    
    % Run Fuzzy Engine
    defuzzout = zeros(1,numDays);
    for i=1:numDays
        input = [stock_struct.ShortTrend(i);
                 stock_struct.VolumeTrend(i);
                 stock_struct.bob(i)];
        defuzzout(i) = evalfis(fis,input);
    end
end
end