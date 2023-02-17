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

    fields = Symbol.(["Open", "High", "Low", "Close", "Volume"]); 
    index  = map(x -> fromUnix2Date.(x.datetime), cl.candles)
    values = Array{Float64}(reduce(hcat, map(x -> [x.open, x.high, x.low, x.close, x.volume], cl.candles))');

    some(TimeSeries.TimeArray(index, values, fields, String(cl.symbol)))
end



###############################################################################
##
##  PriceHistory - Function signiatures to return the JSON return as a String
##
###############################################################################
"""  
```julia
api_getPriceHistoryAsJSON(symbol::String, keys::apiKeys; kw...)
```  
     
Make the TDAmeritradeAPI call to the get\\_price\\_history endpoint, and return the raw JSON.
     
An ErrorTypes.jl Option object will be returned that can be evaluated with ErrorTypes.@?
 
# Arguments
- `symbol::String`: The ticker symbol to fetch price history for.
- `apiKeys::TDAmeritradeAPI.apiKeys`: the apiKeys object containing the CUST_KEY, access
    and refresh tokens.
 
# Keywords
- `periodType::String`: The type of period to show. (default in **bold**):
    - Valid values are **day**, month, year, or ytd (year to date)
- `numPeriods::Int64`: The number of periods to show. 
    - Valid periods by periodType (defaults in **bold**):
      - day: 1, 2, 3, 4, 5, **10**
      - month: **1**, 2, 3, 6
      - year: **1**, 2, 3, 5, 10, 15, 20
      - ytd: **1**
- `frequencyType::String`: The type of frequency with which a new candle is formed.
    - Valid frequencyTypes by periodType (defaults in **bold**):
      - day: **minute**
      - month: daily, **weekly**
      - year: daily, weekly, **monthly**
      - ytd: daily, **weekly**
- `frequency::Int64`: The number of the frequencyType to be included in each candle.
    - Valid frequencies by frequencyType (defaults in **bold**): 
      - minute: **1**, 5, 10, 15, 30
      - daily: **1**
      - weekly: **1**
      - monthly: **1**
- `endDate::DateTime`: End date of data to fetch. If startDate and endDate are provided, period should not be provided.
- `startDate::Union{DateTime, Nothing}`: Start date of data to fetch.
- `needExtendedHoursData`: true to return extended hours data, false for regular market hours only. Default is true.
 
# Example
```julia
api_getPriceHistoryAsJSON("NET", apiKey)
Result{String, String}(Ok("{\"candles\":[{\"open\":60.8,\"high\":60.8,\"low\":60.5,\"close\":60.5,\"volume\":5000,\"datetime\":1675425600000},
                           {\"open\":61.0,\"high\":61.0,\"low\":61.0,\"close\":61.0,\"volume\":200,\"datetime\":1675426080000},
                           {\"open\":61.75,\"high\":61.8,\"low\":61.75,\"close\":61.8,\"volume\":2347,\"datetime\":1675426260000}
[...]
```
"""
function api_getPriceHistoryAsJSON(symbol::String, keys::apiKeys; 
                                   periodType::String = "day", numPeriods::Int64 = (periodType == "day" ? 10 : 1), 
                                   frequencyType::String = (periodType == "day" ? "minute" : 
                                                            periodType in ["month", "ytd"] ? "weekly" : "monthly" ),
                                   frequency::Int64 = 1, endDate::DateTime = now(), startDate::Union{DateTime, Nothing} = nothing, 
                                   needExtendedHoursData = true
                                  )::ErrorTypes.Result{String, String}

    _getPriceHistory(symbol, keys, periodType = periodType, numPeriods = numPeriods, 
                     frequencyType = frequencyType, frequency = frequency, 
                     endDate = endDate, startDate = startDate, needExtendedHoursData = needExtendedHoursData);
end

#################################################################################################
##
##  PriceHistory - Function signiatures to return DataFrames, and TimeSeries.TimeArray
##
#################################################################################################
"""                                                                                                                                                                                                                    
```julia
api_getPriceHistoryAsDataFrame(symbol::String, keys::apiKeys; kw...)
```  
     
Make the TDAmeritradeAPI call to the get\\_price\\_history endpoint, and return a DataFrame
     
An ErrorTypes.jl Option object will be returned that can be evaluated with ErrorTypes.@?
 
# Arguments
- `symbol::String`: The ticker symbol to fetch price history for.
- `apiKeys::TDAmeritradeAPI.apiKeys`: the apiKeys object containing the CUST_KEY, access
    and refresh tokens.
 
# Keywords
- `periodType::String`: The type of period to show. (default in **bold**):
    - Valid values are **day**, month, year, or ytd (year to date)
- `numPeriods::Int64`: The number of periods to show. 
    - Valid periods by periodType (defaults in **bold**):
      - day: 1, 2, 3, 4, 5, **10**
      - month: **1**, 2, 3, 6
      - year: **1**, 2, 3, 5, 10, 15, 20
      - ytd: **1**
- `frequencyType::String`: The type of frequency with which a new candle is formed.
    - Valid frequencyTypes by periodType (defaults in **bold**):
      - day: **minute**
      - month: daily, **weekly**
      - year: daily, weekly, **monthly**
      - ytd: daily, **weekly**
- `frequency::Int64`: The number of the frequencyType to be included in each candle.
    - Valid frequencies by frequencyType (defaults in **bold**): 
      - minute: **1**, 5, 10, 15, 30
      - daily: **1**
      - weekly: **1**
      - monthly: **1**
- `endDate::DateTime`: End date of data to fetch. If startDate and endDate are provided, period should not be provided.
- `startDate::Union{DateTime, Nothing}`: Start date of data to fetch.
- `needExtendedHoursData`: true to return extended hours data, false for regular market hours only. Default is true.
 
# Example
```julia
api_getPriceHistoryAsDataFrame("NET", apiKey)
some(5216x6 DataFrame
  Row | Datetime             Open     High     Low      Close    Volume
      | DateTime             Float64  Float64  Float64  Float64  Int64
  --------------------------------------------------------------------
    1 | 2023-02-03T12:00:00  60.8     60.8     60.5     60.5       5000
    2 | 2023-02-03T12:08:00  61.0     61.0     61.0     61.0        200
    3 | 2023-02-03T12:11:00  61.75    61.8     61.75    61.8       2347
    4 | 2023-02-03T12:14:00  61.61    61.61    61.61    61.61       162
    5 | 2023-02-03T12:17:00  61.8     61.8     61.79    61.79       228
    6 | 2023-02-03T12:26:00  61.3     61.3     61.3     61.3        159
    7 | 2023-02-03T12:31:00  61.43    61.43    61.43    61.43       100
    8 | 2023-02-03T12:34:00  61.5     61.5     61.5     61.5        102
    9 | 2023-02-03T12:35:00  61.5     61.5     61.5     61.5        400
   10 | 2023-02-03T12:38:00  61.57    61.61    61.57    61.61       206
[...]
```
"""
function api_getPriceHistoryAsDataFrame(symbol::String, keys::apiKeys; 
                                        periodType::String = "day", numPeriods::Int64 = (periodType == "day" ? 10 : 1), 
                                        frequencyType::String = (periodType == "day" ? "minute" :
                                                                 periodType in ["month", "ytd"] ? "weekly" : "monthly" ),
                                        frequency::Int64 = 1, endDate::DateTime = now(), startDate::Union{DateTime, Nothing} = nothing, 
                                        needExtendedHoursData = true
                                       )::ErrorTypes.Option{DataFrame}

    httpRet = _getPriceHistory(symbol, keys, periodType = periodType, numPeriods = numPeriods, 
                                             frequencyType = frequencyType, frequency = frequency, 
                                             endDate = endDate, startDate = startDate, needExtendedHoursData = needExtendedHoursData);

    _priceHistoryJSONToDataFrame(ErrorTypes.@?(httpRet))
end

"""                                                                                                                                                                                                                    
```julia
api_getPriceHistoryAsTimeArray(symbol::String, keys::apiKeys; kw...)
```  
     
Make the TDAmeritradeAPI call to the get\\_price\\_history endpoint, and return a TimeSeries.TimeArray
     
An ErrorTypes.jl Option object will be returned that can be evaluated with ErrorTypes.@?
 
# Arguments
- `symbol::String`: The ticker symbol to fetch price history for.
- `apiKeys::TDAmeritradeAPI.apiKeys`: the apiKeys object containing the CUST_KEY, access
    and refresh tokens.
 
# Keywords
- `periodType::String`: The type of period to show. (default in **bold**):
    - Valid values are **day**, month, year, or ytd (year to date)
- `numPeriods::Int64`: The number of periods to show. 
    - Valid periods by periodType (defaults in **bold**):
      - day: 1, 2, 3, 4, 5, **10**
      - month: **1**, 2, 3, 6
      - year: **1**, 2, 3, 5, 10, 15, 20
      - ytd: **1**
- `frequencyType::String`: The type of frequency with which a new candle is formed.
    - Valid frequencyTypes by periodType (defaults in **bold**):
      - day: **minute**
      - month: daily, **weekly**
      - year: daily, weekly, **monthly**
      - ytd: daily, **weekly**
- `frequency::Int64`: The number of the frequencyType to be included in each candle.
    - Valid frequencies by frequencyType (defaults in **bold**): 
      - minute: **1**, 5, 10, 15, 30
      - daily: **1**
      - weekly: **1**
      - monthly: **1**
- `endDate::DateTime`: End date of data to fetch. If startDate and endDate are provided, period should not be provided.
- `startDate::Union{DateTime, Nothing}`: Start date of data to fetch.
- `needExtendedHoursData`: true to return extended hours data, false for regular market hours only. Default is true.
 
# Example
```julia
api_getPriceHistoryAsTimeArray("NET", apiKey)
Option{TimeArray}(some(5216x5 TimeArray{Float64, 2, DateTime, Matrix{Float64}} 2023-02-03T12:00:00 to 2023-02-17T00:57:00
|                     | Open  | High  | Low   | Close | Volume |
----------------------------------------------------------------
| 2023-02-03T12:00:00 | 60.8  | 60.8  | 60.5  | 60.5  | 5000.0 |
| 2023-02-03T12:08:00 | 61.0  | 61.0  | 61.0  | 61.0  | 200.0  |
| 2023-02-03T12:11:00 | 61.75 | 61.8  | 61.75 | 61.8  | 2347.0 |
| 2023-02-03T12:14:00 | 61.61 | 61.61 | 61.61 | 61.61 | 162.0  |
| 2023-02-03T12:17:00 | 61.8  | 61.8  | 61.79 | 61.79 | 228.0  |
[...]
```
"""
function api_getPriceHistoryAsTimeArray(symbol::String, keys::apiKeys; 
                                        periodType::String = "day", numPeriods::Int64 = (periodType == "day" ? 10 : 1), 
                                        frequencyType::String = (periodType == "day" ? "minute" :
                                                                 periodType in ["month", "ytd"] ? "weekly" : "monthly" ),
                                        frequency::Int64 = 1, endDate::DateTime = now(), startDate::Union{DateTime, Nothing} = nothing, 
                                        needExtendedHoursData = true
                                       )::ErrorTypes.Option{TimeSeries.TimeArray}
    
    httpRet = _getPriceHistory(symbol, keys, periodType = periodType, numPeriods = numPeriods, 
                                             frequencyType = frequencyType, frequency = frequency, 
                                             endDate = endDate, startDate = startDate, needExtendedHoursData = needExtendedHoursData);
 
    _priceHistoryJSONToTimeArray(ErrorTypes.@?(httpRet))
end

###############################################################################
##
##  Convert JSON to Struct
##
###############################################################################
"""                                                                                                                                                                                                                
```julia
priceHistoryToCandleListStruct(json_string::String)::ErrorTypes.Option{CandleList}
```    
   
Convert the JSON string returned by a TDAmeritradeAPI get\\_price\\_history API call to a CandleList struct.
       
This is largely an internal function to allow later conversions to DataFrame with proper type conversions.
       
An ErrorTypes.jl Option object will be returned that can be evaluated with ErrorTypes.@?
       
# Example 
```julia 
priceHistoryToCandleListStruct(j)
some(TDAmeritradeAPI.CandleList("NET", false, TDAmeritradeAPI.Candle[TDAmeritradeAPI.Candle(1675425600000, 60.8, 60.8, 60.5, 60.5, 5000), 
TDAmeritradeAPI.Candle(1675426080000, 61.0, 61.0, 61.0, 61.0, 200),
TDAmeritradeAPI.Candle(1675426260000, 61.75, 61.8, 61.75, 61.8, 2347),
TDAmeritradeAPI.Candle(1675426440000, 61.61, 61.61, 61.61, 61.61, 162),
[...]  
```  
"""
function priceHistoryToCandleListStruct(json_string::String)::ErrorTypes.Option{CandleList}
    some(JSON3.read(json_string, CandleList))
end

###############################################################################
##
##  Convert Struct to JSON
##
###############################################################################
"""
```julia
priceHistoryToJSON(cl::CandleList)::ErrorTypes.Option{String}
```
  
Convert a CandleList struct cl to a JSON object.
  
An ErrorTypes.jl Option object will be returned that can be evaluated with ErrorTypes.@?
  
The returned JSON will not be in the same format as the initial return from the TDAmeritradeAPI call.
  
# Example
```julia
priceHistoryToJSON(s)
some("{\"symbol\":\"NET\",\"empty\":false,\"candles\":[{\"datetime\":1675425600000,\"open\":60.8,\"high\":60.8,\"low\":60.5,\"close\":60.5,\"volume\":5000},
{\"datetime\":1675426080000,\"open\":61.0,\"high\":61.0,\"low\":61.0,\"close\":61.0,\"volume\":200},
[...]
```
"""
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
"""
```julia
parsePriceHistoryJSONToDataFrame(json_string::String)::ErrorTypes.Option{DataFrame}
```
 
Convert the JSON string returned by a TDAmeritradeAPI get\\_price\\_history API to a DataFrame.
 
Nested JSON objects will be flattened into columns in the output DataFrame.
 
An ErrorTypes.jl Option object will be returned that can be evaluated with ErrorTypes.@?
 
# Example
```julia
parsePriceHistoryJSONToDataFrame(j)
some(5216x6 DataFrame
  Row | Datetime             Open     High     Low      Close    Volume
      | DateTime             Float64  Float64  Float64  Float64  Int64
  --------------------------------------------------------------------
    1 | 2023-02-03T12:00:00  60.8     60.8     60.5     60.5       5000
    2 | 2023-02-03T12:08:00  61.0     61.0     61.0     61.0        200
    3 | 2023-02-03T12:11:00  61.75    61.8     61.75    61.8       2347
    4 | 2023-02-03T12:14:00  61.61    61.61    61.61    61.61       162
    5 | 2023-02-03T12:17:00  61.8     61.8     61.79    61.79       228
    6 | 2023-02-03T12:26:00  61.3     61.3     61.3     61.3        159
    7 | 2023-02-03T12:31:00  61.43    61.43    61.43    61.43       100
    8 | 2023-02-03T12:34:00  61.5     61.5     61.5     61.5        102
    9 | 2023-02-03T12:35:00  61.5     61.5     61.5     61.5        400
   10 | 2023-02-03T12:38:00  61.57    61.61    61.57    61.61       206
[...]
```
"""
function parsePriceHistoryJSONToDataFrame(json_string::String)::ErrorTypes.Option{DataFrame}
    _priceHistoryJSONToDataFrame(json_string)
end

"""
```julia
parsePriceHistoryJSONToTimeArray(json_string::String)::ErrorTypes.Option{TimeSeries.TimeArray}
```

Convert the JSON string returned by a TDAmeritradeAPI get\\_price\\_history API to a TimeSeries.TimeArray.

Nested JSON objects will be flattened into columns in the output TimeSeries.TimeArray.

An ErrorTypes.jl Option object will be returned that can be evaluated with ErrorTypes.@?

# Example
```julia
parsePriceHistoryJSONToTimeArray(j)
Option{TimeArray}(some(5216x5 TimeArray{Float64, 2, DateTime, Matrix{Float64}} 2023-02-03T12:00:00 to 2023-02-17T00:57:00
|                     | Open  | High  | Low   | Close | Volume |
----------------------------------------------------------------
| 2023-02-03T12:00:00 | 60.8  | 60.8  | 60.5  | 60.5  | 5000.0 |
| 2023-02-03T12:08:00 | 61.0  | 61.0  | 61.0  | 61.0  | 200.0  |
| 2023-02-03T12:11:00 | 61.75 | 61.8  | 61.75 | 61.8  | 2347.0 |
| 2023-02-03T12:14:00 | 61.61 | 61.61 | 61.61 | 61.61 | 162.0  |
| 2023-02-03T12:17:00 | 61.8  | 61.8  | 61.79 | 61.79 | 228.0  |
[...]
```
"""
function parsePriceHistoryJSONToTimeArray(json_string::String)::ErrorTypes.Option{TimeSeries.TimeArray}
    _priceHistoryJSONToTimeArray(json_string)
end

