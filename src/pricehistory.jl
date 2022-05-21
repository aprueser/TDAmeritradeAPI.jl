################################################################################
##
## Define Julia structs to hold the return of the API call
##
################################################################################
struct Candle
    close::Float64
    datetime::Int64
    high::Float64
    low::Float64
    open::Float64
    volume::Int64

    ## There are some cases where the API returns a null value for the open, high, low values.  When this happens this will default to using the close value for all 4 ohlc data points.
    function Candle(close::Union{Nothing, LazyJSON.Number{String}}, datetime::LazyJSON.Number{String}, high::Union{Nothing, LazyJSON.Number{String}}, low::Union{Nothing, LazyJSON.Number{String}}, 
                    open::Union{Nothing, LazyJSON.Number{String}}, volume::LazyJSON.Number{String})
                    
        new(isnothing(close) ? -1 : convert(Float64, close), 
            convert(Int64, datetime), 
            isnothing(high)  ? isnothing(close) ? -1 : convert(Float64, close) : convert(Float64, high), 
            isnothing(low)   ? isnothing(close) ? -1 : convert(Float64, close) : convert(Float64, low), 
            isnothing(open)  ? isnothing(close) ? -1 : convert(Float64, close) : convert(Float64, open), 
            convert(Int64, volume))
    end
end

struct CandleList
    candles::Array{Candle}
    empty::Bool
    symbol::String
end

################################################################################
##
## Define custom HTTP error messages for the API call
##
################################################################################
priceHistoryHTTPErrorMsg = Dict{Int64, String}(
    400 => "Must pass a non null value in the symbol parameter",
    401 => "Unauthorized",
    403 => "Forbidden",
    404 => "Not Found",
    500 => "Internal Error in Price History API Call; review input parameters, particularly the custKey"
)

################################################################################
##
##  PriceHistory - Core API Call Functions
##
##  The length of the OHLC data: numPeriods + periodType (eg: 10 year)
##  The type of each OHLC data point: frequency + frequencyType (15 minute)
################################################################################
function _getPriceHistory(symbol::String, keys::apiKeys; periodType::String = "day", numPeriods::Int64 = (periodType == "day" ? 10 : 1), 
                                             frequencyType::String = (periodType == "day" ? "minute" :
                                                                      periodType in ["month", "ytd"] ? "weekly" : "monthly" ),
                                             frequency::Int64 = 1, endDate::DateTime = now(), startDate::Union{DateTime, Nothing} = nothing, needExtendedHoursData = true)
    @argcheck length(symbol) > 0
    @argcheck lowercase(periodType) in ["day", "month", "year", "ytd", nothing]
    @argcheck lowercase(periodType) == "day" ? numPeriods in [1, 2, 3, 4, 5, 10] :
              lowercase(periodType) == "month" ? numPeriods in [1, 2, 3, 6] :
              lowercase(periodType) == "year" ? numPeriods in [1, 2, 3, 5, 10, 15, 20] : numPeriods == 1
    @argcheck lowercase(frequencyType) in ["minute", "daily", "weekly", "monthly"]
    @argcheck lowercase(frequencyType) == "minute" ? frequency in [1, 5, 10 , 15, 30] : frequency == 1
    @argcheck !isnothing(startDate) || !isnothing(periodType)
    @argcheck !isnothing(startDate) ? endDate > startDate : true

    queryParams = ["{symbol}" => symbol];

    if !isnothing(periodType) 
        bodyParams = Dict{String, Union{Number, String, Bool}}("periodType"            => periodType,
                                                              "period"                => numPeriods,
                                                              "frequencyType"         => frequencyType,
                                                              "frequency"             => frequency,
                                                              "needExtendedHoursData" => needExtendedHoursData,
                                                              "apikey"                => keys.custKey);
    end

    if !isnothing(startDate)
        bodyParams = Dict{String, Union{Number, String, Bool}}("startDate"             => Dates.value(startDate) - Dates.UNIXEPOCH,
                                                              "endDate"               => Dates.value(endDate) - Dates.UNIXEPOCH,
                                                              "frequencyType"         => frequencyType,
                                                              "frequency"             => frequency,
                                                              "needExtendedHoursData" => needExtendedHoursData,
                                                              "apikey"                => keys.custKey);
    end

    res = doHTTPCall("get_price_history", queryParams = queryParams, bodyParams = bodyParams);

    if haskey(res, :code) && res[:code] != 200
        res[:body] = haskey(priceHistoryHTTPErrorMsg, res[:code]) ? priceHistoryHTTPErrorMsg[res[:code]] * ". Symbol: " * symbol : "Invalid API Call for symbol " * symbol;
    end

    return(res)
end

###############################################################################
##
##  Quotes - Function signiatures to return the JSON return as a String
##
###############################################################################
function api_getPriceHistoryRaw(symbol::String, keys::apiKeys; periodType::String = "day", numPeriods::Int64 = (periodType == "day" ? 10 : 1), 
                                                               frequencyType::String = (periodType == "day" ? "minute" :
                                                                                        periodType in ["month", "ytd"] ? "weekly" : "monthly" ),
                                                               frequency::Int64 = 1, endDate::DateTime = now(), startDate::Union{DateTime, Nothing} = nothing, needExtendedHoursData = true)

    return(_getPriceHistory(symbol, keys, periodType = periodType, numPeriods = numPeriods, 
                                          frequencyType = frequencyType, frequency = frequency, 
                                          endDate = endDate, startDate = startDate, needExtendedHoursData = needExtendedHoursData));
end

#################################################################################################
##
##  Quotes - Function signiatures to return DataFrames, Temporal.TS, and TimeSeries.TimeArray
##
#################################################################################################
function api_getPriceHistoryDF(symbol::String, keys::apiKeys; periodType::String = "day", numPeriods::Int64 = (periodType == "day" ? 10 : 1), 
                                               frequencyType::String = (periodType == "day" ? "minute" :
                                                                        periodType in ["month", "ytd"] ? "weekly" : "monthly" ),
                                               frequency::Int64 = 1, endDate::DateTime = now(), startDate::Union{DateTime, Nothing} = nothing, needExtendedHoursData = true)::DataFrame

    df::DataFrame = DataFrame()

    httpRet = _getPriceHistory(symbol, keys, periodType = periodType, numPeriods = numPeriods, 
                                             frequencyType = frequencyType, frequency = frequency, 
                                             endDate = endDate, startDate = startDate, needExtendedHoursData = needExtendedHoursData);

    if haskey(httpRet, :code) && httpRet[:code] == 200
        ljson = LazyJSON.value(httpRet[:body])

        if haskey(ljson, "empty") && ljson["empty"] == false
            df = priceHistoryToDataFrame(ljson)
        else
            df = DataFrame([:httpCode => httpRet[:code], :httpMessage => httpRet[:message], :results => "No OHLC data found for symbol: " * symbol])
        end
    else
        df = DataFrame([:httpCode => httpRet[:code], :httpMessage => httpRet[:message], :results => httpRet[:body]])
    end
    
    return(df);
end

function api_getPriceHistoryTS(symbol::String, keys::apiKeys; periodType::String = "day", numPeriods::Int64 = (periodType == "day" ? 10 : 1), 
                                               frequencyType::String = (periodType == "day" ? "minute" :
                                                                        periodType in ["month", "ytd"] ? "weekly" : "monthly" ),
                                               frequency::Int64 = 1, endDate::DateTime = now(), startDate::Union{DateTime, Nothing} = nothing, needExtendedHoursData = true)::Temporal.TS

    df::Temporal.TS = Temporal.TS()

    httpRet = _getPriceHistory(symbol, keys, periodType = periodType, numPeriods = numPeriods, 
                                             frequencyType = frequencyType, frequency = frequency, 
                                             endDate = endDate, startDate = startDate, needExtendedHoursData = needExtendedHoursData);
    
    if httpRet[:code] == 200
        ljson = LazyJSON.value(httpRet[:body])

        if ljson["empty"] == false
            df = priceHistoryToTemporalTS(ljson)
        end
    end

    return(df)
end

function api_getPriceHistoryTA(symbol::String, keys::apiKeys; periodType::String = "day", numPeriods::Int64 = (periodType == "day" ? 10 : 1), 
                                               frequencyType::String = (periodType == "day" ? "minute" :
                                                                        periodType in ["month", "ytd"] ? "weekly" : "monthly" ),
                                               frequency::Int64 = 1, endDate::DateTime = now(), startDate::Union{DateTime, Nothing} = nothing, needExtendedHoursData = true)::TimeSeries.TimeArray
    
    httpRet = _getPriceHistory(symbol, keys, periodType = periodType, numPeriods = numPeriods, 
                                             frequencyType = frequencyType, frequency = frequency, 
                                             endDate = endDate, startDate = startDate, needExtendedHoursData = needExtendedHoursData);
    
    if httpRet[:code] == 200
        ljson = LazyJSON.value(httpRet[:body])

        if ljson["empty"] == false
            return(priceHistoryToTimeSeriesTA(ljson))
        end
    end

    return(nothing)
end

###################################################################################################
##
##  PriceHistory to DataFrames, Temporal.TS, and TimeSeries.TimeArray format conversion functions
##   1. DataFrame
##   2. TimeSeries TimeArray
##   3. Temporal TS
##
##  Dates are in America/NewYork, and reflect when the candle was opened
##
###################################################################################################
function parseRawPriceHistoryToDataFrame(httpRet::Dict{Symbol, Union{Int16, String, Vector{UInt8}}}, symbol::String)
    
    if haskey(httpRet, :code) && httpRet[:code] == 200
        ljson = LazyJSON.value(httpRet[:body])

        if haskey(ljson, "empty") && ljson["empty"] == false
            df = priceHistoryToDataFrame(ljson)
        else
            df = DataFrame([:httpCode => httpRet[:code], :httpMessage => httpRet[:message], :results => "No OHLC data found for symbol: " * symbol])
        end
    else
        df = DataFrame([:httpCode => httpRet[:code], :httpMessage => httpRet[:message], :results => httpRet[:body]])
    end
    
    return(df);
end

function parseRawPriceHistoryToTemporalTS(httpRet::Dict{Symbol, Union{Int16, String, Vector{UInt8}}}, symbol::String)
    
    if haskey(httpRet, :code) && httpRet[:code] == 200
        ljson = LazyJSON.value(httpRet[:body])

        if haskey(ljson, "empty") && ljson["empty"] == false
            df = priceHistoryToTemporalTS(ljson)
        else
            df = DataFrame([:httpCode => httpRet[:code], :httpMessage => httpRet[:message], :results => "No OHLC data found for symbol: " * symbol])
        end
    else
        df = DataFrame([:httpCode => httpRet[:code], :httpMessage => httpRet[:message], :results => httpRet[:body]])
    end
    
    return(df);
end

function parseRawPriceHistoryToTimeSeriesTA(httpRet::Dict{Symbol, Union{Int16, String, Vector{UInt8}}}, symbol::String)
    
    if haskey(httpRet, :code) && httpRet[:code] == 200
        ljson = LazyJSON.value(httpRet[:body])

        if haskey(ljson, "empty") && ljson["empty"] == false
            df = priceHistoryToTimeSeriesTA(ljson)
        else
            df = DataFrame([:httpCode => httpRet[:code], :httpMessage => httpRet[:message], :results => "No OHLC data found for symbol: " * symbol])
        end
    else
        df = DataFrame([:httpCode => httpRet[:code], :httpMessage => httpRet[:message], :results => httpRet[:body]])
    end
    
    return(df);
end

function priceHistoryToDataFrame(ljson::LazyJSON.Object{Nothing, String})::DataFrame
    cl::CandleList = convert(CandleList, ljson)

    fields = Vector{String}(["Open", "High", "Low", "Close", "Volume"]);
    index  =  map(x -> fromUnix2Date(x.datetime), cl.candles)
    values = Array{Float64}(reduce(hcat, map(x -> [x.open, x.high, x.low, x.close, x.volume], cl.candles))');

    df = DataFrame(values, fields, copycols = false)
    DataFrames.insertcols!(df, 1, :Datetime => index, :Symbol => ljson["symbol"])

    return df
end

function priceHistoryToTemporalTS(ljson::LazyJSON.Object{Nothing, String})::Temporal.TS
    cl::CandleList = convert(CandleList, ljson)

    fields = Vector{String}(["Open", "High", "Low", "Close", "Volume"]);
    index  =  map(x -> fromUnix2Date(x.datetime), cl.candles)
    values = Array{Float64}(reduce(hcat, map(x -> [x.open, x.high, x.low, x.close, x.volume], cl.candles))');

    ohlcv = Temporal.TS(values, index, fields)

    return(ohlcv)
end

function priceHistoryToTimeSeriesTA(ljson::LazyJSON.Object{Nothing, String})::TimeSeries.TimeArray
    cl::CandleList = convert(CandleList, ljson)

    fields = Vector{String}(["Open", "High", "Low", "Close", "Volume"]);
    index  =  map(x -> fromUnix2Date(x.datetime), cl.candles)
    values = Array{Float64}(reduce(hcat, map(x -> [x.open, x.high, x.low, x.close, x.volume], cl.candles))');

    ohlcv = TimeSeries.TimeArray(index, values, fields, String(ljson["symbol"]))

    return(ohlcv)
end