% spmartin
% imports stock price data from Yahoo! Finance
% expects a .csv file w/ the below column headers
%
% Date,Open,High,Low,Close,Adj Close,Volume
function price_struct = yahoo_import(filename)

if ~contains(filename, '.csv')
    error('Only .csv files from Yahoo! supported')
end
opts = detectImportOptions(fullfile(filename));
price_struct = readtable(fullfile(filename),opts,'ReadVariableNames',false);

% convert the date into MATLAB datetime format
price_struct.Date = datetime(price_struct.Date);

% get rid of any NaN entries
price_struct = rmmissing(price_struct);

end