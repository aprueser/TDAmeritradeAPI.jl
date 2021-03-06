################################################################################
##
## Define Julia structs to hold the return of the API call
##
################################################################################ 
mutable struct MutualFund
    assetType::String
    assetMainType::String
    cusip::String
    symbol::String 
    description::String
    closePrice::Float64
    netChange::Float64
    totalVolume::Int64
    tradeTimeInLong::Union{Int64, Missing}
    exchange::String
    exchangeName::String
    digits::Int32
    fiftyTwoWkHigh::Union{Float64, Nothing}
    fiftyTwoWkLow::Union{Float64, Nothing}
    nAV::Float64
    peRatio::Float64
    divAmount::Float64
    divYield::Float64
    divDate::String
    securityStatus::String
    netPercentChangeInDouble::Float64
    delayed::Bool
    realtimeEntitled::Bool
end

mutable struct Future
    assetType::String
    assetMainType::String
    cusip::Union{String, Nothing}
    symbol::String
    bidPriceInDouble::Float64
    askPriceInDouble::Float64
    lastPriceInDouble::Float64
    bidSizeInLong::Int64
    askSizeInLong::Int64
    bidId::String
    askId::String
    totalVolume::Int64
    lastSizeInLong::Int64
    quoteTimeInLong::Union{Int64, Missing}
    tradeTimeInLong::Union{Int64, Missing}
    highPriceInDouble::Float64
    lowPriceInDouble::Float64
    closePriceInDouble::Float64
    exchange::String
    description::String
    lastId::String
    openPriceInDouble::Float64
    changeInDouble::Float64
    futurePercentChange::Float64
    exchangeName::String
    securityStatus::String
    openInterest::Int64
    mark::Float64
    tick::Float64
    tickAmount::Float64
    product::String
    futurePriceFormat::String
    futureTradingHours::String
    futureIsTradable::Bool
    futureMultiplier::Float64
    futureIsActive::Bool
    futureSettlementPrice::Float64
    futureActiveSymbol::String
    futureExpirationDate::Union{Int64, Missing}
    delayed::Bool
    realtimeEntitled::Bool
end

mutable struct FutureOption
    assetType::String
    assetMainType::String
    cusip::String
    symbol::String
    bidPriceInDouble::Float64
    askPriceInDouble::Float64
    lastPriceInDouble::Float64
    highPriceInDouble::Float64
    lowPriceInDouble::Float64
    closePriceInDouble::Float64
    description::String
    openPriceInDouble::Float64
    netChangeInDouble::Float64
    openInterest::Float64
    exchangeName::String
    securityStatus::String
    volatility::Float64
    moneyIntrinsicValueInDouble::Float64
    multiplierInDouble::Float64
    digits::Int32
    strikePriceInDouble::Float64
    contractType::String
    underlying::String
    timeValueInDouble::Float64
    deltaInDouble::Float64
    gammaInDouble::Float64
    thetaInDouble::Float64
    vegaInDouble::Float64
    rhoInDouble::Float64
    mark::Float64
    tick::Float64
    tickAmount::Float64
    futureIsTradable::Bool
    futureTradingHours::String
    futurePercentChange::Float64
    futureIsActive::Bool
    futureExpirationDate::Union{Int64, Missing}
    expirationType::String
    exerciseType::String
    inTheMoney::Bool
end

mutable struct Index
    assetType::String
    assetMainType::String
    cusip::String
    symbol::String
    description::String
    lastPrice::Float64
    openPrice::Float64
    highPrice::Float64
    lowPrice::Float64
    closePrice::Float64
    netChange::Float64
    totalVolume::Int64
    tradeTimeInLong::Union{Int64, Missing}
    exchange::String
    exchangeName::String
    digits::Int32
    fiftyTwoWkHigh::Union{Float64, Nothing}
    fiftyTwoWkLow::Union{Float64, Nothing}
    securityStatus::String
    netPercentChangeInDouble::Float64
    delayed::Bool
    realtimeEntitled::Bool
end

mutable struct Option
    assetType::String
    assetMainType::String
    cusip::Union{String, Nothing}
    symbol::String
    description::String
    bidPrice::Float64
    bidSize::Int32
    askPrice::Float64
    askSize::Int32
    lastPrice::Float64
    lastSize::Int32
    openPrice::Float64
    highPrice::Float64
    lowPrice::Float64
    closePrice::Float64
    netChange::Float64
    totalVolume::Int64
    quoteTimeInLong::Union{Int64, Missing}
    tradeTimeInLong::Union{Int64, Missing}
    mark::Float64
    openInterest::Float64
    volatility::Float64
    moneyIntrinsicValue::Float64
    multiplier::Float64
    digits::Int32
    strikePrice::Float64
    contractType::String
    underlying::String
    expirationDay::Int32
    expirationMonth::Int32
    expirationYear::Int32
    daysToExpiration::Int32
    timeValue::Float64
    deliverables::String
    delta::Float64
    gamma::Float64
    theta::Float64
    vega::Float64
    rho::Float64
    securityStatus::String
    theoreticalOptionValue::Float64
    underlyingPrice::Float64
    uvExpirationType::String
    exchange::String
    exchangeName::String
    lastTradingDay::Union{Int64, Missing}
    settlementType::String
    netPercentChangeInDouble::Float64
    markChangeInDouble::Float64
    markPercentChangeInDouble::Float64
    impliedYield::Float64
    isPennyPilot::Bool
    delayed::Bool
    realtimeEntitled::Bool
end

mutable struct Forex
    assetType::String
    assetMainType::String
    cusip::Union{String, Nothing}
    symbol::String
    bidPriceInDouble::Float64
    askPriceInDouble::Float64
    lastPriceInDouble::Float64
    bidSizeInLong::Int64
    askSizeInLong::Int64
    totalVolume::Int64
    lastSizeInLong::Int64
    quoteTimeInLong::Union{Int64, Missing}
    tradeTimeInLong::Union{Int64, Missing}
    highPriceInDouble::Float64
    lowPriceInDouble::Float64
    closePriceInDouble::Float64
    exchange::String
    description::String
    openPriceInDouble::Float64
    changeInDouble::Float64
    percentChange::Float64
    exchangeName::String
    digits::Int32
    securityStatus::String
    tick::Float64
    tickAmount::Float64
    product::String
    tradingHours::String
    isTradable::Bool
    marketMaker::String
    fiftyTwoWkHighInDouble::Union{Float64, Nothing}
    fiftyTwoWkLowInDouble::Union{Float64, Nothing}
    mark::Float64
    delayed::Bool
    realtimeEntitled::Bool
end

mutable struct ETF
    assetType::String
    assetMainType::String
    cusip::String
    assetSubType::String
    symbol::String
    description::String
    bidPrice::Float64
    bidSize::Int32
    bidId::String
    askPrice::Float64
    askSize::Int32
    askId::String
    lastPrice::Float64
    lastSize::Int32
    lastId::String
    openPrice::Float64
    highPrice::Float64
    lowPrice::Float64
    bidTick::String
    closePrice::Float64
    netChange::Float64
    totalVolume::Int64
    quoteTimeInLong::Union{Int64, Missing}
    tradeTimeInLong::Union{Int64, Missing}
    mark::Float64
    exchange::String
    exchangeName::String
    marginable::Bool
    shortable::Bool
    volatility::Float64
    digits::Int32
    fiftyTwoWkHigh::Union{Float64, Nothing}
    fiftyTwoWkLow::Union{Float64, Nothing}
    nAV::Float64
    peRatio::Float64
    divAmount::Float64
    divYield::Float64
    divDate::String
    securityStatus::String
    regularMarketLastPrice::Float64
    regularMarketLastSize::Int32
    regularMarketNetChange::Float64
    regularMarketTradeTimeInLong::Union{Int64, Missing}
    netPercentChangeInDouble::Float64
    markChangeInDouble::Float64
    markPercentChangeInDouble::Float64
    regularMarketPercentChangeInDouble::Float64
    delayed::Bool
    realtimeEntitled::Bool
end

mutable struct Equity
    assetType::String
    assetMainType::String
    cusip::String
    symbol::String
    description::String
    bidPrice::Float64
    bidSize::Int32
    bidId::String
    askPrice::Float64
    askSize::Int32
    askId::String
    lastPrice::Float64
    lastSize::Int32
    lastId::String
    openPrice::Float64
    highPrice::Float64
    lowPrice::Float64
    bidTick::String
    closePrice::Float64
    netChange::Float64
    totalVolume::Int64
    quoteTimeInLong::Union{Int64, Missing}
    tradeTimeInLong::Union{Int64, Missing}
    mark::Float64
    exchange::String
    exchangeName::String
    marginable::Bool
    shortable::Bool
    volatility::Float64
    digits::Int32
    fiftyTwoWkHigh::Union{Float64, Nothing}
    fiftyTwoWkLow::Union{Float64, Nothing}
    nAV::Float64
    peRatio::Float64
    divAmount::Float64
    divYield::Float64
    divDate::String
    securityStatus::String
    regularMarketLastPrice::Float64
    regularMarketLastSize::Int32
    regularMarketNetChange::Float64
    regularMarketTradeTimeInLong::Union{Int64, Missing}
    netPercentChangeInDouble::Float64
    markChangeInDouble::Float64
    markPercentChangeInDouble::Float64
    regularMarketPercentChangeInDouble::Float64
    delayed::Bool
    realtimeEntitled::Bool
end

################################################################################
##
## Define custom HTTP error messages for the API call
##
################################################################################
quotesHTTPErrorMsg = Dict{Int64, String}(
    400 => "Must pass a non null value in the parameter.",
    401 => "Unauthorized",
    403 => "Forbidden",
    404 => "Instrument for the symbol/cisip Not Found.",
    406 => "Bad symbol regex, or the number of symbols search is over the allowed max."
)

###################################################################################
##
##  Quotes - Core API Call Functions
##   Get Quote doesn't handle FOREX and FUTURE symbols that require a / in the symbol
##   The Get Quotes API does properly handle these as it can encode the / as %2F properly in the query portion of the URL
##
###################################################################################
function _getQuote(symbol::String, apiKeys::TDAmeritradeAPI.apiKeys)
    @argcheck length(strip(symbol)) > 0
    @argcheck startswith(symbol, r"[A-Za-z\$]")

    queryParams = ["{symbol}" => symbol];

    bodyParams = Dict{String, Union{Number, String, Bool}}("apikey" => apiKeys.custKey);

    res = doHTTPCall("get_quote", queryParams = queryParams, bodyParams = bodyParams);

    if haskey(res, :code) && res[:code] != 200
        res[:body] = haskey(quotesHTTPErrorMsg, res[:code]) ? quotesHTTPErrorMsg[res[:code]] * ". Symbol: " * symbol : "Invalid API Call for symbol " * symbol;
    end

    return(res)
end

function _getQuotes(symbols::String, apiKeys::TDAmeritradeAPI.apiKeys)
    @argcheck length(strip.(symbols)) > 0

    bodyParams = Dict{String, Union{Number, String, Bool}}("symbol" => symbols,
                                                          "apikey" => apiKeys.custKey);

    res = doHTTPCall("get_quotes", bodyParams = bodyParams);

    if haskey(res, :code) && res[:code] != 200
        res[:body] = haskey(quotesHTTPErrorMsg, res[:code]) ? quotesHTTPErrorMsg[res[:code]] * ". Symbols: " * symbols : "Invalid API Call for symbols " * symbols;
    end

    return(res)
end

###############################################################################
##
##  Quotes - Function signiatures to return the JSON return as a String
##
###############################################################################
function api_getQuoteRaw(symbol::String, apiKeys::TDAmeritradeAPI.apiKeys)
    httpRet = _getQuote(symbol, apiKeys);

    return(httpRet)
end

function api_getQuotesRaw(symbols::Vector{String}, apiKeys::TDAmeritradeAPI.apiKeys)
    httpRet = _getQuotes(join(symbols, ","), apiKeys);

    return(httpRet)
end

function api_getQuotesRaw(symbols::String, apiKeys::TDAmeritradeAPI.apiKeys)
    httpRet = _getQuotes(symbols, apiKeys);

    return(httpRet)
end

###############################################################################
##
##  Quotes - Function signiatures to return DataFrames
##
###############################################################################
function api_getQuoteDF(symbol::String, apiKeys::TDAmeritradeAPI.apiKeys)
    httpRet = _getQuote(symbol, apiKeys);

    if haskey(httpRet, :code) && httpRet[:code] == 200
        ljson = LazyJSON.value(httpRet[:body])

        if length(ljson) > 0 
            df = quotesToDataFrame(ljson)
        else
            df = DataFrame([:httpCode => httpRet[:code], :httpMessage => httpRet[:message], :results => "No Quote data found for symbol: " * symbol])
        end
    else
        df = DataFrame([:httpCode => httpRet[:code], :httpMessage => httpRet[:message], :results => httpRet[:body]])
    end
    
    return(df);
end

function api_getQuotesDF(symbols::Vector{String}, apiKeys::TDAmeritradeAPI.apiKeys)::DataFrame
    return(api_getQuotesDF(join(symbols, ","), apiKeys));
end

function api_getQuotesDF(symbols::String, apiKeys::TDAmeritradeAPI.apiKeys)::DataFrame
    httpRet = _getQuotes(symbols, apiKeys);

    if haskey(httpRet, :code) && httpRet[:code] == 200
        ljson = LazyJSON.value(httpRet[:body])

        if length(ljson) > 0 
            df = quotesToDataFrame(ljson)
        else
            df = DataFrame([:httpCode => httpRet[:code], :httpMessage => httpRet[:message], :results => "No Quote data found for symbols: " * symbols])
        end
    else
        df = DataFrame([:httpCode => httpRet[:code], :httpMessage => httpRet[:message], :results => httpRet[:body]])
    end
    
    return(df);
end

################################################################################
##
##  Quotes to DataFrame format conversion functions
##
################################################################################
function quotesToDataFrame(ljson::LazyJSON.Object{Nothing, String})::DataFrame
    
    vecs = Dict{String, Vector{Any}}()
    vecs["MUTUAL_FUND"] = Vector{MutualFund}()
    vecs["FUTURE"] = Vector{Future}()
    vecs["FUTURE_OPTION"] = Vector{FutureOption}()
    vecs["INDEX"] = Vector{Index}()
    vecs["OPTION"] = Vector{Option}()
    vecs["FOREX"] = Vector{Forex}()
    vecs["ETF"] = Vector{Equity}()
    vecs["EQUITY"] = Vector{Equity}()

    for d in collect(values(ljson))
        ## Handle the individual returns as they could all be a different type
        if d["assetType"] == "MUTUAL_FUND"
            mf::MutualFund = convert(MutualFund, d)
            mf.fiftyTwoWkHigh = d["52WkHigh"];
            mf.fiftyTwoWkLow  = d["52WkLow"];
            push!(vecs["MUTUAL_FUND"], mf)
        elseif d["assetType"] == "FUTURE"
            f::Future = convert(Future, d)
            push!(vecs["FUTURE"], f)
        elseif d["assetType"] == "FUTURE_OPTION"   ## Untested .. what's a valid Futures Option symbol to test?
            fo::FutureOptions = convert(FutureOption, d)
            push!(vecs["FUTURE_OPTION"], fo)
        elseif d["assetType"] == "INDEX"
            i::Index = convert(Index, d)
            i.fiftyTwoWkHigh = d["52WkHigh"];
            i.fiftyTwoWkLow  = d["52WkLow"];
            push!(vecs["INDEX"], i)
        elseif d["assetType"] == "OPTION"
            op::Option = convert(Option, d)
            push!(vecs["OPTION"], op)
        elseif d["assetType"] == "FOREX"
            fx::Forex = convert(Forex, d)
            fx.fiftyTwoWkHighInDouble = d["52WkHighInDouble"];
            fx.fiftyTwoWkLowInDouble  = d["52WkLowInDouble"];
            push!(vecs["FOREX"], fx)
        elseif d["assetType"] == "ETF"
            etf::ETF = convert(ETF, d)
            etf.fiftyTwoWkHigh = d["52WkHigh"];
            etf.fiftyTwoWkLow  = d["52WkLow"];
            push!(vecs["ETF"], etf)
        elseif d["assetType"] == "EQUITY"
            eq::Equity = convert(Equity, d)
            eq.fiftyTwoWkHigh = d["52WkHigh"];
            eq.fiftyTwoWkLow  = d["52WkLow"];
            push!(vecs["EQUITY"], eq)
        else
            ## We got an unknown assetType, skip it
        end
    end

    df = DataFrame(vecs["ETF"], copycols = false)
    append!(df, DataFrame(vecs["MUTUAL_FUND"], copycols = false), cols = :union);
    append!(df, DataFrame(vecs["FUTURE"], copycols = false), cols = :union);
    append!(df, DataFrame(vecs["FUTURE_OPTION"], copycols = false), cols = :union);
    append!(df, DataFrame(vecs["INDEX"], copycols = false), cols = :union);
    append!(df, DataFrame(vecs["OPTION"], copycols = false), cols = :union);
    append!(df, DataFrame(vecs["FOREX"], copycols = false), cols = :union);
    append!(df, DataFrame(vecs["EQUITY"], copycols = false), cols = :union);

    dateFmt = Dates.DateFormat("yyyy-mm-dd HH:MM:SS.sss");
    dfCols = ["quoteTimeInLong", "tradeTimeInLong", "lastTradingDay", "regularMarketTradeTimeInLong", "futureExpirationDate", "divDate"]

    for c in dfCols
        if hasproperty(df, c)
            ## Replace Missings first to simplify the @transform
            c != "divDate" && @transform!(df, $c = replace($c, missing => 0))

            c == "quoteTimeInLong" && transform!(df, :quoteTimeInLong .=> fromUnix2Date .=> :quoteTimeInLong)
            c == "tradeTimeInLong" && transform!(df, :tradeTimeInLong .=> fromUnix2Date .=> :tradeTimeInLong)
            c == "lastTradingDay" && transform!(df, :lastTradingDay .=> fromUnix2Date .=> :lastTradingDay)
            c == "regularMarketTradeTimeInLong" && transform!(df, :regularMarketTradeTimeInLong .=> fromUnix2Date .=> :regularMarketTradeTimeInLong)
            c == "futureExpirationDate" && transform!(df, :futureExpirationDate .=> fromUnix2Date .=> :futureExpirationDate)
            c == "divDate" && @transform! df @byrow begin :divDate = DateTime(ismissing(:divDate) ? "1900-01-01 00:00:00.000" : :divDate, dateFmt) end

        end
    end
    
    return(df)
end