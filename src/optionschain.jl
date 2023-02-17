
################################################################################
##
## Define known valid input values for the API call
##
################################################################################
validContractType = ["CALL", "PUT", "ALL"];
validStrategy     = ["SINGLE", "COVERED", "VERTICAL", "CALENDAR", "STRANGLE", "STRADDLE", 
                     "BUTTERFLY", "CONDOR", "DIAGONAL", "COLLAR", "ROLL"];
validRange        = ["ITM", "NTM", "OTM", "SAK", "SBK", "SNK", "ALL"];
validExpMonth     = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", 
                     "NOV", "DEC", "ALL"]
validOptionType   = ["S", "NS", "ALL"]

################################################################################
##
## Define Julia structs to hold the return of the API call
##
################################################################################
mutable struct Underlying
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

    Underlying() = new()
end

StructTypes.StructType(::Type{Underlying}) = StructTypes.Mutable();
StructTypes.idproperty(::Type{Underlying}) = :symbol

mutable struct OptionDeliverables
    symbol::String
    assetType::String
    deliverableUnits::Union{Float64, Nothing}
    currencyType::Union{String, Nothing}

    OptionDeliverables() = new()
end

StructTypes.StructType(::Type{OptionDeliverables}) = StructTypes.Mutable();
StructTypes.idproperty(::Type{OptionDeliverables}) = :symbol

@with_kw mutable struct OptionDetail
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
    strikePrice::Union{Float64, Nothing}
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
    pennyPilot::Union{Bool, Nothing}
    mini::Union{Bool, Nothing}
    nonStandard::Union{Bool, Nothing}
    inTheMoney::Union{Bool, Nothing}
end 

StructTypes.StructType(::Type{OptionDetail}) = StructTypes.Mutable();
StructTypes.idproperty(::Type{OptionDetail}) = :symbol

##############################################################################################
##
## Custom Map over the callExpDateMap and putExpDateMap structures in the return
##  JSON to skip the complex Dict{String, Dict{String, Vector{OptionDetail} ordering 
##  of the data as the Dict keys do not add ny value.
##
##############################################################################################
mutable struct ExpDateMap
    dateMap::Vector{OptionDetail}                                                         
                                                                                          
    ExpDateMap(x::Vector{OptionDetail}) = new(x)                                          
end                                                                                       
                                                  
function StructTypes.construct(ExpDateMap, x::Dict{String, Any})::ExpDateMap                                        
    v = Vector{OptionDetail}()                                                            
                                                                                          
    for expDateDict in values(x)                                                          
        for strikeDict in values(expDateDict)                                             
            for opd in values(strikeDict)                                                 
                push!(v, OptionDetail(;NamedTuple{Tuple(Symbol.(keys(opd)))}(values(opd))...))                                                                                                                                                                         
            end                                                                           
        end                                                                               
    end                                                                                   
                                                                                          
    ExpDateMap(v)                                                                         
end

StructTypes.StructType(::Type{ExpDateMap}) = StructTypes.CustomStruct();                  
StructTypes.lower(x::ExpDateMap) = x.dateMap

mutable struct OptionChain
    symbol::String
    status::String
    underlying::Union{Underlying, Nothing}
    strategy::String
    interval::Union{Float64, Nothing}
    isDelayed::Union{Bool, Nothing}
    isIndex::Union{Bool, Nothing}
    interestRate::Union{Float64, Nothing}
    underlyingPrice::Union{Float64, Nothing}
    volatility::Union{Float64, Nothing}
    daysToExpiration::Union{Float64, Nothing}
    numberOfContracts::Union{Int64, Nothing}
    callExpDateMap::Union{ExpDateMap, Nothing}
    putExpDateMap::Union{ExpDateMap, Nothing}

    OptionChain() = new()
end

StructTypes.StructType(::Type{OptionChain}) = StructTypes.Mutable();
StructTypes.idproperty(::Type{OptionChain}) = :symbol

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
function _getOptionChain(symbol::String, apiKeys::TDAmeritradeAPI.apiKeys; 
                         contractType::String = "ALL", strikeCount::Int64 = 25, 
                         includeQuotes::Bool = false, strategy::String = "SINGLE", 
                         interval::Int64 = 10, strike::Union{Float64, Nothing} = nothing, 
                         range::String = "ALL", fromDate::Date = today(), 
                         toDate::Union{Date, Nothing} = nothing, expMonth::String = "ALL",
                         optionType::String = "ALL"
                        )::ErrorTypes.Result{String, String}
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

    bodyParams = Dict{String, Union{Float64, String, Bool}}("symbol"          => symbol,
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

    doHTTPCall("get_option_chain", bodyParams = bodyParams);
end

###############################################################################
##
## Internal mapping functions from JSON to DataFrame
##
###############################################################################
function _optionChainJSONToDataFrame(rawJSON::String)::ErrorTypes.Option{DataFrame}
    oc::OptionChain = ErrorTypes.@?(optionChainToOptionChainStruct(rawJSON))

    df::DataFrame = DataFrame(vcat(oc.putExpDateMap.dateMap, oc.callExpDateMap.dateMap), 
                              copycols = false);

    DataFrames.insertcols!(df, 1, :Status => oc.status, 
                                  :Underlying => HTTP.unescapeuri(oc.symbol), 
                                  :UnderlyingPrice => oc.underlyingPrice)

    if !isnothing(oc.underlying)
        underlyingDF = singleSturctToDataFrame(oc.underlying)

        df = DataFrames.innerjoin(df, underlyingDF, on = :Underlying => :symbol, makeunique = true, 
                                  renamecols = "" => "_underlying");

        transform!(df, :quoteTime_underlying .=> fromUnix2Date .=> :quoteTime_underlying)
        transform!(df, :tradeTime_underlying .=> fromUnix2Date .=> :tradeTime_underlying)
    end

    if oc.status != "FAILED"
        transform!(df, :quoteTimeInLong .=> fromUnix2Date .=> :quoteTimeInLong)
        transform!(df, :tradeTimeInLong .=> fromUnix2Date .=> :tradeTimeInLong)
        transform!(df, :expirationDate .=> fromUnix2Date .=> :expirationDate)
        transform!(df, :lastTradingDay .=> fromUnix2Date .=> :lastTradingDay)
    end

    some(df)
end

###############################################################################
##
##  Option Chain - Function signiatures to return the JSON return as a String
##
###############################################################################
"""
```julia
api_getOptionChainAsJSON(symbol::String, apiKeys::TDAmeritradeAPI.apiKeys; kw...)::ErrorTypes.Option{DataFrame}
```

Make the TDAmeritradeAPI call to the get\\_option\\_chain endpoint, and return the raw JSON.

An ErrorTypes.jl Option object will be returned that can be evaluated with ErrorTypes.@?

# Arguments
- `symbol::String`: the underlying stock symbol to fetch the Option Chain for.
- `apiKeys::TDAmeritradeAPI.apiKeys`: the apiKeys object containing the CUST_KEY, access
    and refresh tokens.

# Keywords
- `contractType::String = "ALL"`: Type of contracts to return in the chain. Can be CALL, PUT, or ALL. 
- `strikeCount::Int64 = 25`: The number of strikes to return above and below the at-the-money price.
- `includeQuotes::Bool = false`: Include quotes for options in the option chain. Can be TRUE or FALSE. 
- `strategy::String = "SINGLE"`: Passing a value returns a Strategy Chain. Possible values are SINGLE, 
    COVERED, VERTICAL, CALENDAR, STRANGLE, STRADDLE, BUTTERFLY, CONDOR, DIAGONAL, COLLAR, or ROLL
- `interval::Int64 = 10`: Strike interval for spread strategy chains
- `strike::Union{Float64, Nothing} = nothing`: Provide a strike price to return options only at that 
    strike price.
- `range::String = "ALL"`: Returns options for the given range. Possible values are:
    ITM: In-the-money
    NTM: Near-the-money
    OTM: Out-of-the-money
    SAK: Strikes Above Market
    SBK: Strikes Below Market
    SNK: Strikes Near Market
    ALL: All Strikes
- `fromDate::Date = today()`: Only return expirations after this date. For strategies, expiration refers 
    to the nearest term expiration in the strategy. 
    Valid ISO-8601 formats are: yyyy-MM-dd and yyyy-MM-dd'T'HH:mm:ssz.'
- `toDate::Union{Date, Nothing} = nothing`: Only return expirations before this date. For strategies, 
    expiration refers to the nearest term expiration in the strategy. 
    Valid ISO-8601 formats are: yyyy-MM-dd and yyyy-MM-dd'T'HH:mm:ssz.'
- `expMonth::String = "ALL"`: Return only options expiring in the specified month. 
    Month is given in the three character format. Example: JAN
- `optionType::String = "ALL"`: Type of contracts to return. Possible values are:
    S: Standard contracts
    NS: Non-standard contracts
    ALL: All contracts

"""
function api_getOptionChainAsJSON(symbol::String, apiKeys::TDAmeritradeAPI.apiKeys; 
                                  contractType::String = "ALL", strikeCount::Int64 = 25, 
                                  includeQuotes::Bool = false, strategy::String = "SINGLE", 
                                  interval::Int64 = 10, strike::Union{Float64, Nothing} = nothing, 
                                  range::String = "ALL", fromDate::Date = today(), 
                                  toDate::Union{Date, Nothing} = nothing, expMonth::String = "ALL", 
                                  optionType::String = "ALL"
                                 )::ErrorTypes.Result{String, String}

    _getOptionChain(symbol, apiKeys, contractType = contractType, strikeCount = strikeCount, 
                    includeQuotes = includeQuotes, strategy = strategy, interval = interval,
                    strike = strike, range = range, fromDate = fromDate, toDate = toDate, 
                    expMonth = expMonth, optionType = optionType);
end

###############################################################################
##
##  Option Chain - Function signiatures to return DataFrames
##
###############################################################################
"""
```julia
api_getOptionChainAsDataFrame(symbol::String, apiKeys::TDAmeritradeAPI.apiKeys; kw...)::ErrorTypes.Option{DataFrame}
```

Make the TDAmeritradeAPI call to the get\\_option\\_chain endpoint, and return a DataFrame

An ErrorTypes.jl Option object will be returned that can be evaluated with ErrorTypes.@?

# Arguments
See [`api_getOptionChainAsJSON`](@ref).

# Keywords
See [`api_getOptionChainAsJSON`](@ref).
"""
function api_getOptionChainAsDataFrame(symbol::String, apiKeys::TDAmeritradeAPI.apiKeys; 
                                       contractType::String = "ALL", strikeCount::Int64 = 25, 
                                       includeQuotes::Bool = false, strategy::String = "SINGLE", 
                                       interval::Int64 = 10, strike::Union{Float64, Nothing} = nothing, 
                                       range::String = "ALL", fromDate::Date = today(),
                                       toDate::Union{Date, Nothing} = nothing, expMonth::String = "ALL",
                                       optionType::String = "ALL"
                                      )::ErrorTypes.Option{DataFrame}

    httpRet = _getOptionChain(symbol, apiKeys, contractType = contractType, strikeCount = strikeCount, 
                              includeQuotes = includeQuotes, strategy = strategy, interval = interval,
                              strike = strike, range = range, fromDate = fromDate, toDate = toDate, 
                              expMonth = expMonth, optionType = optionType);

     _optionChainJSONToDataFrame(ErrorTypes.@?(httpRet))
end

###############################################################################
##
##  Convert JSON to Struct
##
###############################################################################
"""
```julia
optionChainToOptionChainStruct(json_string::String)::ErrorTypes.Option{OptionChain}
```

Convert the JSON string returned by the TDAmeritradeAPI get\\_option\\_chain API call to an OptionChain struct.

This is largely an internal function to allow later conversions to DataFrame with proper type conversions.

An ErrorTypes.jl Option object will be returned that can be evaluated with ErrorTypes.@?

# Example
```julia
optionChainToOptionChainStruct(js)
some(TDAmeritradeAPI.OptionChain("NET", "SUCCESS", nothing, "SINGLE", 0.0, true, false, 0.1,
[...]
```
"""
function optionChainToOptionChainStruct(json_string::String)::ErrorTypes.Option{OptionChain}
    some(JSON3.read(json_string, OptionChain))
end

###############################################################################
##
##  Convert Struct to JSON
##
###############################################################################
"""
```julia
optionChainToJSON(oc::OptionChain)::ErrorTypes.Option{String}
```

Convert an OptionChain struct oc to a JSON object.

An ErrorTypes.jl Option object will be returned that can be evaluated with ErrorTypes.@?

The returned JSON will not be in the same format as the initial return from the TDAmeritradeAPI call.

# Example
```julia
optionChainToJSON(oc)
some("{\"symbol\":\"NET\",\"status\":\"SUCCESS\",\"underlying\":null,\"strategy\":\"SINGLE\" 
[...]
```
"""
function optionChainToJSON(oc::OptionChain)::ErrorTypes.Option{String}
    some(JSON3.write(oc))
end

################################################################################
##
##  OptionsChain to DataFrame format conversion functions
##
##  Note: The OptionsDeliverableList is not converted into the DataFrame
##
################################################################################
"""
```julia
parseOptionChainJSONToDataFrame(json_string::String)::ErrorTypes.Option{DataFrame}
```

Convert the JSON string returned by the TDAmeritradeAPI get\\_option\\_chain API call to a DataFrame.

The put and call maps will be appended into a single DataFrame, with the PUT rows coming first.

Nested JSON objects will be flattened into columns in the output DataFrame.

An ErrorTypes.jl Option object will be returned that can be evaluated with ErrorTypes.@?

# Example
```julia
parseOptionChainJSONToDataFrame(js)
some(596x52 DataFrame
 Row | Status  Underlying UnderlyingPrice putCall symbol description exchangeName bid ask
[...]
```
"""
function parseOptionChainJSONToDataFrame(json_string::String)::ErrorTypes.Option{DataFrame}
    _optionChainJSONToDataFrame(json_string)
end
