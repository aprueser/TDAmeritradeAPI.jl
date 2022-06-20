
################################################################################
##
## Define known valid input values for the API call
##
################################################################################
validContractType = ["CALL", "PUT", "ALL"];
validStrategy     = ["SINGLE", "COVERED", "VERTICAL", "CALENDAR", "STRANGLE", "STRADDLE", "BUTTERFLY", "CONDOR", "DIAGONAL", "COLLAR", "ROLL"];
validRange        = ["ITM", "NTM", "OTM", "SAK", "SBK", "SNK", "ALL"];
validExpMonth     = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC", "ALL"]
validOptionType   = ["S", "NS", "ALL"]

################################################################################
##
## Define Julia structs to hold the return of the API call
##
################################################################################
struct Underlying
    ask::Union{Float64, Nothing}
    askSize::Int64
    bid::Union{Float64, Nothing}
    bidSize::Int64
    change::Union{Float64, Nothing}
    close::Union{Float64, Nothing}
    delayed::Union{Bool, Nothing}
    description::String
    exchangeName::String
    fiftyTwoWeekHigh::Union{Float64, Nothing}
    fiftyTwoWeekLow::Union{Float64, Nothing}
    highPrice::Union{Float64, Nothing}
    last::Union{Float64, Nothing}
    lowPrice::Union{Float64, Nothing}
    mark::Union{Float64, Nothing}
    markChange::Union{Float64, Nothing}
    markPercentChange::Union{Float64, Nothing}
    openPrice::Union{Float64, Nothing}
    percentChange::Union{Float64, Nothing}
    quoteTime::Int64
    symbol::String
    totalVolume::Int64
    tradeTime::Int64
end

struct OptionDeliverables
    symbol::String
    assetType::String
    deliverableUnits::Union{Float64, Nothing}
    currencyType::Union{String, Nothing}
end

struct StrikePriceMap
    putCall::String
    symbol::String
    description::String
    exchangeName::String
    bid::Union{Float64, Nothing}
    ask::Union{Float64, Nothing}
    last::Union{Float64, Nothing}
    mark::Union{Float64, Nothing}
    bidSize::Int64
    askSize::Int64
    bidAskSize::String
    lastSize::Int64
    highPrice::Union{Float64, Nothing}
    lowPrice::Union{Float64, Nothing}
    openPrice::Union{Float64, Nothing}
    closePrice::Union{Float64, Nothing}
    totalVolume::Int64
    tradeDate::Union{Int64, Nothing}
    tradeTimeInLong::Int64
    quoteTimeInLong::Int64
    netChange::Union{Float64, Nothing}
    volatility::Union{Float64, Nothing}
    delta::Union{Float64, Nothing}
    gamma::Union{Float64, Nothing}
    theta::Union{Float64, Nothing}
    vega::Union{Float64, Nothing}
    rho::Union{Float64, Nothing}
    openInterest::Union{Float64, Nothing}
    timeValue::Union{Float64, Nothing}
    theoreticalOptionValue::Union{Float64, Nothing}
    theoreticalVolatility::Union{Float64, Nothing}
    optionDeliverablesList::Union{Array{OptionDeliverables}, Nothing}
    strikePrice::Union{Number, Nothing}
    expirationDate::Int64
    daysToExpiration::Union{Float64, Nothing}
    expirationType::String
    lastTradingDay::Union{Float64, Nothing}
    multiplier::Union{Float64, Nothing}
    settlementType::String
    deliverableNote::String
    isIndexOption::Union{Bool, Nothing}
    percentChange::Union{Float64, Nothing}
    markChange::Union{Float64, Nothing}
    markPercentChange::Union{Float64, Nothing}
    intrinsicValue::Union{Float64, Nothing}
    inTheMoney::Union{Bool, Nothing}
    mini::Union{Bool, Nothing}
    pennyPilot::Union{Bool, Nothing}
    nonStandard::Union{Bool, Nothing}
end 

struct OptionChain
    symbol::String
    status::String
    strategy::String
    interval::Union{Float64, Nothing}
    isDelayed::Union{Bool, Nothing}
    isIndex::Union{Bool, Nothing}
    interestRate::Union{Float64, Nothing}
    underlyingPrice::Union{Float64, Nothing}
    volatility::Union{Float64, Nothing}
    daysToExpiration::Union{Int64, Nothing}
    numberOfContracts::Union{Int64, Nothing}
    putExpDateMap::Dict{String, Dict{String, Vector{StrikePriceMap}}}
    callExpDateMap::Dict{String, Dict{String, Vector{StrikePriceMap}}}
end

################################################################################
##
## Define custom HTTP error messages for the API call
##
################################################################################
optionChainHTTPErrorMsg = Dict{Int64, String}(
    400 => "Must pass a non null value in the parameter",
    401 => "Unauthorized",
    403 => "Forbidden",
    404 => "Option Chain for symbol not found.",
    500 => "Internal Error in Option Chain API Call; review input parameters, particularly the custKey."
)

###############################################################
##
##  OptionChain - Core API Call Functions
##
##  Range Definition:
##    ITM: In-the-money
##    NTM: Near-the-money
##    OTM: Out-of-the-money
##    SAK: Strikes Above Market
##    SBK: Strikes Below Market
##    SNK: Strikes Near Market
##    ALL: All Strikes
###############################################################
function _getOptionChain(symbol::String, apiKeys::TDAmeritradeAPI.apiKeys; contractType::String = "ALL", strikeCount::Int64 = 25, includeQuotes::Bool = false, strategy::String = "SINGLE", interval::Int64 = 10,
                         strike::Union{Number, Nothing} = nothing, range::String = "ALL", fromDate::Date = today(), toDate::Union{Date, Nothing} = nothing, expMonth::String = "ALL",
                         optionType::String = "ALL")
        @argcheck length(symbol) > 0
        @argcheck uppercase(contractType) in validContractType
        @argcheck strikeCount > 0
        @argcheck uppercase(strategy) in validStrategy
        @argcheck interval > 0
        @argcheck isnothing(strike) || strike > 0
        @argcheck uppercase(range) in validRange
        @argcheck isnothing(toDate) || toDate >= Dates.today()
        @argcheck !isnothing(toDate) ? toDate >= fromDate : true 
        @argcheck uppercase(expMonth) in validExpMonth
        @argcheck uppercase(optionType) in validOptionType 

    bodyParams = Dict{String, Union{Number, String, Bool}}("symbol"          => symbol,
                                                           "contractType"     => contractType,
                                                           "strikeCount"      => strikeCount,
                                                           "includeQuotes"    => includeQuotes,
                                                           "strategy"         => strategy,
                                                           "range"            => range,
                                                           "expMonth"         => expMonth,
                                                           "optionType"       => optionType,
                                                           "apikey"           => apiKeys.custKey);

    if !isnothing(strike)
        bodyParams["strike"] = strike
    end

    if !isnothing(toDate)
        bodyParams["fromDate"] = Dates.format(fromDate, "yyyy-mm-dd")
        bodyParams["toDate"]   = Dates.format(toDate, "yyyy-mm-dd")
    end

    res = doHTTPCall("get_option_chain", bodyParams = bodyParams);

    if haskey(res, :code) && res[:code] != 200
        res[:body] = haskey(optionChainHTTPErrorMsg, res[:code]) ? optionChainHTTPErrorMsg[res[:code]] * ". Symbol: " * symbol : "Invalid API Call for symbol " * symbol;
    end

    return(res)
end

###############################################################################
##
##  Option Chain - Function signiatures to return the JSON return as a String
##
###############################################################################
function api_getOptionChainRaw(symbol::String, apiKeys::TDAmeritradeAPI.apiKeys; contractType::String = "ALL", strikeCount::Int64 = 25, includeQuotes::Bool = false, strategy::String = "SINGLE", interval::Int64 = 10,
                               strike::Union{Number, Nothing} = nothing, range::String = "ALL", fromDate::Date = today(), toDate::Union{Date, Nothing} = nothing, expMonth::String = "ALL",
                               optionType::String = "ALL")

    return(_getOptionChain(symbol, apiKeys, contractType = contractType, strikeCount = strikeCount, includeQuotes = includeQuotes, strategy = strategy, interval = interval,
                                            strike = strike, range = range, fromDate = fromDate, toDate = toDate, expMonth = expMonth, optionType = optionType));

end

###############################################################################
##
##  Quotes - Function signiatures to return DataFrames
##
###############################################################################
function api_getOptionChainDF(symbol::String, apiKeys::TDAmeritradeAPI.apiKeys; contractType::String = "ALL", strikeCount::Int64 = 25, includeQuotes::Bool = false, strategy::String = "SINGLE", interval::Int64 = 10,
                              strike::Union{Number, Nothing} = nothing, range::String = "ALL", fromDate::Date = today(), toDate::Union{Date, Nothing} = nothing, expMonth::String = "ALL",
                              optionType::String = "ALL")::DataFrame

    df::DataFrame = DataFrame()

    httpRet = _getOptionChain(symbol, apiKeys, contractType = contractType, strikeCount = strikeCount, includeQuotes = includeQuotes, strategy = strategy, interval = interval,
                                                  strike = strike, range = range, fromDate = fromDate, toDate = toDate, expMonth = expMonth, optionType = optionType);

    if haskey(httpRet, :code) && httpRet[:code] == 200
        ljson = LazyJSON.value(httpRet[:body])

        if haskey(ljson, "status") && ljson["status"] == "SUCCESS"
            df = optionChainToDataFrame(ljson, symbol)
        else
            df = DataFrame([:httpCode => httpRet[:code], :httpMessage => httpRet[:message], :results => "No Option Chain data found for symbol: " * symbol])
        end
    else
        df = DataFrame([:httpCode => httpRet[:code], :httpMessage => httpRet[:message], :results => httpRet[:body]])
    end
    
    return(df);
end

################################################################################
##
##  OptionsChain to DataFrame format conversion functions
##
##  Note: The OptionsDeliverableList is not converted into the DataFrame
##
################################################################################
function parseRawOptionChainToDataFrame(httpRet::Dict{Symbol, Union{Int16, String, Vector{UInt8}}}, symbol::String)
    
    if length(httpRet) > 0 && haskey(httpRet, :code) && httpRet[:code] == 200
        ljson = LazyJSON.value(httpRet[:body])

        if haskey(ljson, "status") && ljson["status"] == "SUCCESS"
            df = optionChainToDataFrame(ljson, symbol)
        else
            df = DataFrame([:httpCode => httpRet[:code], :httpMessage => httpRet[:message], :results => "No Option Chain data found for symbol: " * symbol])
        end
    else
        df = DataFrame([:httpCode => httpRet[:code], :httpMessage => httpRet[:message], :results => httpRet[:body]])
    end
    
    return(df);
end

function optionChainToDataFrame(ljson::LazyJSON.Object{Nothing, String}, symbol::String)::DataFrame
    
    op::OptionChain = convert(OptionChain, ljson);

    v = Vector{Underlying}()

    if haskey(ljson, "underlying") && !isnothing(ljson["underlying"])
        underlying = convert(Underlying, ljson["underlying"])
        
        push!(v, underlying)
    end

    vspm = Vector{StrikePriceMap}()

    for expDate in keys(op.putExpDateMap)
        for data in values(op.putExpDateMap[expDate])
            push!(vspm, data[1])
        end
    end

    for expDate in keys(op.callExpDateMap)
        for data in values(op.callExpDateMap[expDate])
            push!(vspm, data[1])
        end
    end

    df::DataFrame = DataFrame(vspm, copycols = false);

    DataFrames.insertcols!(df, 1, :Status => op.status, :Underlying => HTTP.unescapeuri(op.symbol), :UnderlyingPrice => op.underlyingPrice)

    if !isempty(v)
        underlyingDF = DataFrame(v, copycols = false)

        df = DataFrames.innerjoin(df, underlyingDF, on = :Underlying => :symbol, makeunique = true, renamecols = "" => "_underlying");

        transform!(df, :quoteTime_underlying .=> fromUnix2Date .=> :quoteTime_underlying)
        transform!(df, :tradeTime_underlying .=> fromUnix2Date .=> :tradeTime_underlying)
    end

    if ljson["status"] != "FAILED"
        transform!(df, :quoteTimeInLong .=> fromUnix2Date .=> :quoteTimeInLong)
        transform!(df, :tradeTimeInLong .=> fromUnix2Date .=> :tradeTimeInLong)
        transform!(df, :expirationDate .=> fromUnix2Date .=> :expirationDate)
        transform!(df, :lastTradingDay .=> fromUnix2Date .=> :lastTradingDay)
    end

    return(df)
end
