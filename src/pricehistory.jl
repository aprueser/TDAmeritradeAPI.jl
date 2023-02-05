################################################################################
##
## Define Julia structs to hold the return of the API call
##
################################################################################
mutable struct Candle
    datetime::Int64
    open::Float64
    high::Float64
    low::Float64
    close::Float64
    volume::Int64

    # Empty Constructor for JSON3.read 
    Candle() = new()
end

StructTypes.StructType(::Type{Candle}) = StructTypes.Mutable();

mutable struct CandleList
    symbol::String
    empty::Bool
    candles::Array{Candle}

    # Empty Constructor for JSON3.read 
    CandleList() = new()
end

StructTypes.StructType(::Type{CandleList}) = StructTypes.Mutable();
StructTypes.idproperty(::Type{CandleList}) = :symbol

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
                                             frequency::Int64 = 1, endDate::DateTime = now(), startDate::Union{DateTime, Nothing} = nothing, needExtendedHoursData = true)::ErrorTypes.Result{String, String}
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
        bodyParams = Dict{String, Union{Number, String, Bool}}("periodType"           => periodType,
                                                              "period"                => numPeriods,
                                                              "frequencyType"         => frequencyType,
                                                              "frequency"             => frequency,
                                                              "needExtendedHoursData" => frequencyType == "minute" ? needExtendedHoursData : false,
                                                              "apikey"                => keys.custKey);
    end

    if !isnothing(startDate)
        bodyParams = Dict{String, Union{Number, String, Bool}}("startDate"            => Dates.value(startDate) - Dates.UNIXEPOCH,
                                                              "endDate"               => Dates.value(endDate) - Dates.UNIXEPOCH,
                                                              "frequencyType"         => frequencyType,
                                                              "frequency"             => frequency,
                                                              "needExtendedHoursData" => frequencyType == "minute" ? needExtendedHoursData : false,
                                                              "apikey"                => keys.custKey);
    end

    doHTTPCall("get_price_history", queryParams = queryParams, bodyParams = bodyParams);
end

#####################################################################################
##
## Internal mapping functions from JSON to DataFrame, and TimeSeries.TA
##
#####################################################################################
function _priceHistoryJSONToDataFrame(rawJSON::String)::ErrorTypes.Option{DataFrame}
    cl::CandleList = ErrorTypes.@?(priceHistoryToCandleListStruct(rawJSON))

    df = none

    if cl.empty == false
        df = DataFrame(cl.candles, copycols = false)
        df[!,:datetime] = fromUnix2Date.(df[!,:datetime])

        DataFrames.rename!(df, [:Datetime, :Open, :High, :Low, :Close, :Volume]);
    end

    some(df)
end

function _priceHistoryJSONToTimeArray(rawJSON::String)::ErrorTypes.Option{TimeSeries.TimeArray}
    cl::CandleList = ErrorTypes.@?(priceHistoryToCandleListStruct(rawJSON))

    fields = Vector{String}(["Open", "High", "Low", "Close", "Volume"]);
    index  = map(x -> fromUnix2Date.(x.datetime), cl.candles)
    values = Array{Float64}(reduce(hcat, map(x -> [x.open, x.high, x.low, x.close, x.volume], cl.candles))');

    some(TimeSeries.TimeArray(index, values, fields, String(cl.symbol)))
end



###############################################################################
##
##  PriceHistory - Function signiatures to return the JSON return as a String
##
###############################################################################
function api_getPriceHistoryAsJSON(symbol::String, keys::apiKeys; periodType::String = "day", numPeriods::Int64 = (periodType == "day" ? 10 : 1), 
                                                               frequencyType::String = (periodType == "day" ? "minute" :
                                                                                        periodType in ["month", "ytd"] ? "weekly" : "monthly" ),
                                                               frequency::Int64 = 1, endDate::DateTime = now(), startDate::Union{DateTime, Nothing} = nothing, needExtendedHoursData = true)::ErrorTypes.Result{String, String}

    _getPriceHistory(symbol, keys, periodType = periodType, numPeriods = numPeriods, 
                     frequencyType = frequencyType, frequency = frequency, 
                     endDate = endDate, startDate = startDate, needExtendedHoursData = needExtendedHoursData);
end

#################################################################################################
##
##  PriceHistory - Function signiatures to return DataFrames, and TimeSeries.TimeArray
##
#################################################################################################
function api_getPriceHistoryAsDataFrame(symbol::String, keys::apiKeys; periodType::String = "day", numPeriods::Int64 = (periodType == "day" ? 10 : 1), 
                                               frequencyType::String = (periodType == "day" ? "minute" :
                                                                        periodType in ["month", "ytd"] ? "weekly" : "monthly" ),
                                               frequency::Int64 = 1, endDate::DateTime = now(), startDate::Union{DateTime, Nothing} = nothing, needExtendedHoursData = true)::ErrorTypes.Option{DataFrame}

    httpRet = _getPriceHistory(symbol, keys, periodType = periodType, numPeriods = numPeriods, 
                                             frequencyType = frequencyType, frequency = frequency, 
                                             endDate = endDate, startDate = startDate, needExtendedHoursData = needExtendedHoursData);

    _priceHistoryToDataFrame(ErrorTypes.@?(httpRet))
end

function api_getPriceHistoryAsTimeArray(symbol::String, keys::apiKeys; periodType::String = "day", numPeriods::Int64 = (periodType == "day" ? 10 : 1), 
                                               frequencyType::String = (periodType == "day" ? "minute" :
                                                                        periodType in ["month", "ytd"] ? "weekly" : "monthly" ),
                                               frequency::Int64 = 1, endDate::DateTime = now(), startDate::Union{DateTime, Nothing} = nothing, needExtendedHoursData = true)::ErrorTypes.Option{TimeSeries.TimeArray}
    
    httpRet = _getPriceHistory(symbol, keys, periodType = periodType, numPeriods = numPeriods, 
                                             frequencyType = frequencyType, frequency = frequency, 
                                             endDate = endDate, startDate = startDate, needExtendedHoursData = needExtendedHoursData);
 
    _priceHistoryToTimeArray(ErrorTypes.@?(httpRet))
end

###############################################################################
##
##  Convert JSON to Struct
##
###############################################################################
function priceHistoryToCandleListStruct(json_string::String)::ErrorTypes.Option{CandleList}
    some(JSON3.read(json_string, CandleList))
end

###############################################################################
##
##  Convert Struct to JSON
##
###############################################################################
function priceHistoryToJSON(cl::CandleList)::ErrorTypes.Option{String}
    some(JSON3.write(cl))
end

###################################################################################################
##
##  PriceHistory to DataFrames, and TimeSeries.TimeArray format conversion functions
##   1. DataFrame
##   2. TimeSeries TimeArray
##
##  Dates are in America/NewYork, and reflect when the candle was opened
##
###################################################################################################
function parsePriceHistoryJSONToDataFrame(json_string::String)::ErrorTypes.Option{DataFrame}
    _priceHistoryToDataFrame(json_string)
end

function parsePriceHistoryJSONToTimeArray(json_string::String)::ErrorTypes.Option{TimeSeries.TimeArray}
    _priceHistoryToTimeArray(json_string)
end

