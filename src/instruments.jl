################################################################################
##
## Define Julia structs to hold the return of the API call
##
################################################################################
@with_kw mutable struct FundamentalData
    symbol::String
    high52::Float64
    low52::Float64
    dividendAmount::Float64
    dividendYield::Float64
    dividendDate::String
    peRatio::Float64
    pegRatio::Float64
    pbRatio::Float64
    prRatio::Float64
    pcfRatio::Float64
    grossMarginTTM::Float64
    grossMarginMRQ::Float64
    netProfitMarginTTM::Float64
    netProfitMarginMRQ::Float64
    operatingMarginTTM::Float64
    operatingMarginMRQ::Float64
    returnOnEquity::Float64
    returnOnAssets::Float64
    returnOnInvestment::Float64
    quickRatio::Float64
    currentRatio::Float64
    interestCoverage::Float64
    totalDebtToCapital::Float64
    ltDebtToEquity::Float64
    totalDebtToEquity::Float64
    epsTTM::Float64
    epsChangePercentTTM::Float64
    epsChangeYear::Float64
    epsChange::Float64
    revChangeYear::Float64
    revChangeTTM::Float64
    revChangeIn::Float64
    sharesOutstanding::Float64
    marketCapFloat::Float64
    marketCap::Float64
    bookValuePerShare::Float64
    shortIntToFloat::Float64
    shortIntDayToCover::Float64
    divGrowthRate3Year::Float64
    dividendPayAmount::Float64
    dividendPayDate::String
    beta::Float64
    vol1DayAvg::Float64
    vol10DayAvg::Float64
    vol3MonthAvg::Float64
end
StructTypes.StructType(::Type{FundamentalData}) = StructTypes.Mutable();
StructTypes.idproperty(::Type{FundamentalData}) = :symbol

@with_kw mutable struct Instrument
    bondPrice::Union{Float64, Nothing} = nothing
    cusip::Union{String, Nothing}      = nothing
    symbol::String                     = "" 
    description::String                = ""
    exchange::String                   = ""
    assetType::String                  = ""
    fundamental::Union{FundamentalData, Nothing} = nothing
end
StructTypes.StructType(::Type{Instrument}) = StructTypes.Mutable();
StructTypes.idproperty(::Type{Instrument}) = :symbol

## Handle the Anonymous Dict that all search results are returned as
mutable struct InstrumentDict <: AbstractDict{Symbol, Any}
    instruments::Dict{Symbol, Instrument}

    InstrumentDict(x::Dict{Symbol, Any}) = begin
        for (k, v) in x
            v["fundamental"] = haskey(v, "fundamental") ? FundamentalData(;NamedTuple{Tuple(Symbol.(keys(v["fundamental"])))}(values(v["fundamental"]))...) : nothing;
            x[k] = Instrument(;NamedTuple{Tuple(Symbol.(keys(v)))}(values(v))...)
        end

        new(x)
    end
end
Base.pairs(x::InstrumentDict)             = pairs(x.instruments)
Base.length(x::InstrumentDict)            = length(x.instruments)
Base.iterate(x::InstrumentDict)           = iterate(x.instruments)
Base.iterate(x::InstrumentDict, i::Int64) = iterate(x.instruments, i)
StructTypes.StructType(::Type{InstrumentDict}) = StructTypes.DictType();

## Handle the anonymous array that all Instrument looks ups are returned as
mutable struct InstrumentArray <: AbstractArray{Instrument, 1}     
    instruments::Vector{Instrument}
end
Base.getindex(inst::InstrumentArray, i::Int) = getindex(inst.instruments, i)
Base.size(inst::InstrumentArray)             = size(inst.instruments)

StructTypes.StructType(::Type{InstrumentArray}) = StructTypes.ArrayType();

################################################################################
##
## Define custom HTTP error messages for the API call
##
################################################################################
instrumentsHTTPErrorMsg = Dict{Int64, String}(
    400 => "Must pass a non null value in the parameter.",
    401 => "Unauthorized",
    403 => "Forbidden",
    404 => "Instrument for the symbol/cisip Not Found.",
    406 => "Bad symbol regex, or the number of symbols search is over the allowed max."
)

###################################################################################
##
## Instruments - Core API Call Functions
##
###################################################################################
function _getInstrument(cusip::String, apiKeys::TDAmeritradeAPI.apiKeys)::ErrorTypes.Result{String, String}
    @argcheck !ismissing(cusip)
    @argcheck !isnothing(cusip)
    @argcheck length(cusip) > 0

    queryParams = ["{cusip}" => cusip];

    bodyParams = Dict{String, Union{Number, String, Bool}}("apikey" => apiKeys.custKey);

    doHTTPCall("get_instrument", queryParams = queryParams, bodyParams = bodyParams);
end

function _searchInstruments(symbol::String, projection::String, apiKeys::TDAmeritradeAPI.apiKeys)::ErrorTypes.Result{String, String}
    @argcheck !ismissing(symbol)
    @argcheck !isnothing(symbol)
    @argcheck length(symbol) > 0
    @argcheck projection in ["fundamental", "symbol-search", "symbol-regex", "desc-search", "desc-regex"]

    bodyParams = Dict{String, Union{Number, String, Bool}}("symbol"    => symbol,
                                                          "projection" => projection,
                                                          "apikey"     => apiKeys.custKey);

    doHTTPCall("search_instruments", bodyParams = bodyParams);
end

################################################################################
##
##  Instruments to DataFrame format conversion function
##
#################################################################################
function _instrumentJSONToDataFrame(rawJSON::String, api_call::String)::ErrorTypes.Option{DataFrame}
    i::Union{InstrumentArray, InstrumentDict} = api_call == "array" ? ErrorTypes.@?(instrumentsToInstrumentArrayStruct(rawJSON)) : ErrorTypes.@?(instrumentsToInstrumentDictStruct(rawJSON))
   
    df = DataFrame(values(i), copycols = false)

    if df[1,:fundamental] != nothing
       dff = DataFrame(df[!,:fundamental])
       df = innerjoin(df, dff, on = :symbol)
    end

    select!(df, Not(:fundamental))

    return some(df)
end


###############################################################################
##
##  Instruments - Function signiatures to return the JSON return as a String
##
###############################################################################
"""
```julia
api_getInstrumentAsJSON(cusip::String, apiKeys::TDAmeritradeAPI.apiKeys)::ErrorTypes.Result{String, String}
```
Make the TDAmeritradeAPI call to the get\\_instrument endpoint, and return the raw JSON.

An ErrorTypes.jl Option object will be returned that can be evaluated with ErrorTypes.@?

# Example
```julia
api_getInstrumentAsJSON("NET", apiKey)
Result{String, String}(Ok("[{\"cusip\":\"18915M107\",\"symbol\":\"NET\",\"description\":\"CLOUDFLARE INC COM CL A\",\"exchange\":\"EQY\",\"assetType\":\"EQUITY\"}]"))
```
"""
function api_getInstrumentAsJSON(cusip::String, apiKeys::TDAmeritradeAPI.apiKeys)::ErrorTypes.Result{String, String}
   _getInstrument(cusip, apiKeys);
end

"""
```julia
api_searchInstrumentsAsJSON(symbol::String, projection::String, apiKeys::TDAmeritradeAPI.apiKeys)::ErrorTypes.Result{String, String}
```
Make the TDAmeritradeAPI call to the search\\_instruments endpoint, and return the raw JSON.

An ErrorTypes.jl Option object will be returned that can be evaluated with ErrorTypes.@?

# Arguments
- `projection::String`: The type of request:
   - symbol-search: Retrieve instrument data of a specific symbol or cusip
   - symbol-regex: Retrieve instrument data for all symbols matching regex. 
     - Example: symbol=XYZ.* will return all symbols beginning with XYZ
   - desc-search: Retrieve instrument data for instruments whose description contains the word supplied.
     - Example: symbol=FakeCompany will return all instruments with FakeCompany in the description.
   - desc-regex: Search description with full regex support.
     - Example: symbol=XYZ.[A-C] returns all instruments whose descriptions contain a word beginning with XYZ followed by a character A through C.
   - fundamental: Returns fundamental data for a single instrument specified by exact symbol

# Example
```julia
api_searchInstrumentsAsJSON("NET", "symbol-search", apiKey)
Result{String, String}(Ok("{\"NET\":{\"cusip\":\"18915M107\",\"symbol\":\"NET\",\"description\":\"Cloudflare, Inc. Class A Common Stock\",\"exchange\":\"NYSE\",\"assetType\":\"EQUITY\"}}"))

api_searchInstrumentsAsJSON("NET.*", "symbol-regex", apiKey)
Result{String, String}(Ok("{\"NET\":{\"cusip\":\"18915M107\",\"symbol\":\"NET\",\"description\":\"Cloudflare, Inc. Class A Common Stock\",\"exchange\":\"NYSE\",\"assetType\":\"EQUITY\"},
                            \"NETTF\":{\"cusip\":\"G6427A102\",\"symbol\":\"NETTF\",\"description\":\"Netease Inc Ordinary Shares (PC)\",\"exchange\":\"Pink Sheet\",\"assetType\":\"EQUITY\"},
[...]

api_searchInstrumentsAsJSON("Cloud", "desc-search", apiKey)
Result{String, String}(Ok("{\"18911R100\":{\"cusip\":\"18911R100\",\"symbol\":\"18911R100\",\"description\":\"CLOUD MEDICAL DOCTOR SOFTWARE\",\"exchange\":\"Unknown\",\"assetType\":\"UNKNOWN\"},
                            \"CLGUF\":{\"cusip\":\"18913C101\",\"symbol\":\"CLGUF\",\"description\":\"CLOUD NINE WEB3 TECHNOLOGIES INC Common Shares (QB)\",\"exchange\":\"Pink Sheet\",\"assetType\":\"EQUITY\"},
[...]

api_searchInstrumentsAsJSON(".*Semiconductor.*", "desc-regex", apiKey)
Result{String, String}(Ok("{\"AOSL\":{\"cusip\":\"G6331P104\",\"symbol\":\"AOSL\",\"description\":\"Alpha and Omega Semiconductor Limited - Common Shares\",\"exchange\":\"NASDAQ\",\"assetType\":\"EQUITY\"},
                            \"BESIY\":{\"cusip\":\"073320103\",\"symbol\":\"BESIY\",\"description\":\"BE Semiconductor Industries NV New York Registry Shares (PC)\",\"exchange\":\"Pink Sheet\",\"assetType\":\"EQUITY\"},
[...]

api_searchInstrumentsAsJSON("NET", "fundamental", apiKey)
Result{String, String}(Ok("{\"NET\":{\"fundamental\":{\"symbol\":\"NET\",\"high52\":132.45,\"low52\":37.37,\"dividendAmount\":0.0,\"dividendYield\":0.0,
[...]
```
"""
function api_searchInstrumentsAsJSON(symbol::String, projection::String, apiKeys::TDAmeritradeAPI.apiKeys)::ErrorTypes.Result{String, String}
    _searchInstruments(symbol, projection, apiKeys);
end

###############################################################################
##
##  Instruments - Function signiatures to return DataFrames
##
###############################################################################
"""
```julia
api_getInstrumentAsDataFrame(cusip::String, apiKeys::TDAmeritradeAPI.apiKeys)::ErrorTypes.Option{DataFrame}
```
Make the TDAmeritradeAPI call to the get\\_instrument endpoint, and return a DataFrame

An ErrorTypes.jl Option object will be returned that can be evaluated with ErrorTypes.@?

# Example
```julia
api_getInstrumentAsDataFrame("NET", apiKey)
some(1x7 DataFrame
 Row | bondPrice  cusip      symbol  description              exchange  assetType
     | Nothing    String     String  String                   String    String   
 --------------------------------------------------------------------------------
   1 |            18915M107  NET     CLOUDFLARE INC COM CL A  EQY       EQUITY)

```

See Also: [`api_getInstrumentAsJSON`](@ref).

"""
function api_getInstrumentAsDataFrame(cusip::String, apiKeys::TDAmeritradeAPI.apiKeys)::ErrorTypes.Option{DataFrame}

    httpRet = _getInstrument(cusip, apiKeys);

    _instrumentJSONToDataFrame(ErrorTypes.@?(httpRet), "array")
end

"""
```julia
api_searchInstrumentsAsDataFrame(symbol::String, projection::String, apiKeys::TDAmeritradeAPI.apiKeys)::ErrorTypes.Option{DataFrame}
```
Make the TDAmeritradeAPI call to the search\\_instruments endpoint, and return a DataFrame

An ErrorTypes.jl Option object will be returned that can be evaluated with ErrorTypes.@?

# Example
```julia
api_searchInstrumentsAsDataFrame("NET", "symbol-search", apiKey)
some(1x7 DataFrame
 Row | bondPrice  cusip      symbol  description                        exchange  assetType
     | Nothing    String     String  String                             String    String   
 ------------------------------------------------------------------------------------------
   1 |            18915M107  NET     Cloudflare, Inc. Class A Common    NYSE      EQUITY)

api_searchInstrumentsAsDataFrame("NET.*", "symbol-regex", apiKey)
some(13x7 DataFrame
 Row | bondPrice  cusip      symbol  description                        exchange    assetType
     | Nothing    String     String  String                             String      String   
 --------------------------------------------------------------------------------------------
   1 |            29287L205  NETZ    Engine No. 1 ETF Trust Engine No   BATS        ETF
   2 |            64114L102  NETO    NetObjects, Inc. Common Stock (C   Pink Sheet  EQUITY
   3 |            Y2294C107  NETI    Eneti Inc. Common Stock            NYSE        EQUITY
   4 |            629567207  NETC.U  Nabors Energy Transition Corp. U   NYSE        EQUITY
[...]

api_searchInstrumentsAsDataFrame("Cloud", "desc-search", apiKey)
some(21x7 DataFrame
 Row | bondPrice  cusip      symbol     description                        exchange    assetType
     | Nothing    String     String     String                             String      String   
 -----------------------------------------------------------------------------------------------
   1 |            G2215E109  CDBDF      CLOUDBREAK DISCOVERY PLC Ordinar   Pink Sheet  EQUITY
   2 |            18912C102  18912C102  CLOUDMD SOFTWARE & SERVICES INC    Unknown     UNKNOWN
   3 |            189125057  189125057  Cloudcommerce Inc                  Unknown     UNKNOWN
   4 |            18912C102  PHGRF      CLOUDMD SOFTWARE & SVCS INC Comm   Pink Sheet  EQUITY
[...]

api_searchInstrumentsAsDataFrame("NET", "fundamental", apiKey)
some(1x51 DataFrame
 Row | bondPrice cusip symbol description exchange assetType high52 low52 dividendAmount dividendYield dividendDate ...
[...]

```

See Also: [`api_searchInstrumentsAsJSON`](@ref).

"""
function api_searchInstrumentsAsDataFrame(symbol::String, projection::String, apiKeys::TDAmeritradeAPI.apiKeys)::ErrorTypes.Option{DataFrame}

    httpRet = _searchInstruments(symbol, projection, apiKeys)

    _instrumentJSONToDataFrame(ErrorTypes.@?(httpRet), "dict")
end

###############################################################################
##
##  Convert JSON to Struct
##
###############################################################################
"""                                                                                                                                                                                                                
```julia
instrumentsToInstrumentDictStruct(json_string::String)::ErrorTypes.Option{InstrumentDict}
```
   
Convert the JSON string returned by the TDAmeritradeAPI search\\_instruments API call to an InstrumentDict struct.

This is largely an internal function to allow later conversions to DataFrame with proper type conversions.
   
An ErrorTypes.jl Option object will be returned that can be evaluated with ErrorTypes.@?
   
# Example
```julia
instrumentsToInstrumentDictStruct(read("./test/sample/instrument_search_multiple_results.json", String))
some(TDAmeritradeAPI.InstrumentDict(Symbol("594NSP015") => TDAmeritradeAPI.Instrument
[...]
, :MSFT33 => TDAmeritradeAPI.Instrument
[...]
, :MSFT => TDAmeritradeAPI.Instrument
[...]
```
"""
function instrumentsToInstrumentDictStruct(json_string::String)::ErrorTypes.Option{InstrumentDict}
    some(JSON3.read(json_string, InstrumentDict))
end

"""                                                                                                                                                                                                                
```julia
instrumentsToInstrumentArrayStruct(json_string::String)::ErrorTypes.Option{InstrumentArray}
```
   
Convert the JSON string returned by the TDAmeritradeAPI get\\_instrument API call to an InstrumentArray struct.

This is largely an internal function to allow later conversions to DataFrame with proper type conversions.
   
An ErrorTypes.jl Option object will be returned that can be evaluated with ErrorTypes.@?
   
# Example
```julia
instrumentsToInstrumentArrayStruct(read("./test/sample/instrument_equity.json", String))
some(TDAmeritradeAPI.Instrument[TDAmeritradeAPI.Instrument(nothing, "18915M107", "NET", "CLOUDFLARE INC COM CL A", "EQY", "EQUITY", nothing)])
```
"""
function instrumentsToInstrumentArrayStruct(json_string::String)::ErrorTypes.Option{InstrumentArray}
    some(JSON3.read(json_string, InstrumentArray))
end

###############################################################################
##
##  Convert Struct to JSON
##
###############################################################################
"""                                                                                                                                                                                                                
```julia
instrumentsToJSON(i::Union{InstrumentArray, InstrumentDict})::ErrorTypes.Option{String}
```    
   
Convert an InstrumentArray or InstrumentDict struct to a JSON object.
       
An ErrorTypes.jl Option object will be returned that can be evaluated with ErrorTypes.@?
       
The returned JSON will not be in the same format as the initial return from the TDAmeritradeAPI call.
       
# Example 
```julia 
s = @?(instrumentsToInstrumentArrayStruct(read("./test/sample/instrument_equity.json", String)))

instrumentsToJSON(s)
some("[{\"bondPrice\":null,\"cusip\":\"18915M107\",\"symbol\":\"NET\",\"description\":\"CLOUDFLARE INC COM CL A\",\"exchange\":\"EQY\",\"assetType\":\"EQUITY\",\"fundamental\":null}]")
```  
"""
function instrumentsToJSON(i::Union{InstrumentArray, InstrumentDict})::ErrorTypes.Option{String}
    some(JSON3.write(i))
end

################################################################################
##
##  Instruments to DataFrame format conversion functions
##
################################################################################
"""                                                                                                                                                                                                                
```julia
parseInstrumentsJSONToDataFrame(json_string::String, api_call::String)::ErrorTypes.Option{DataFrame}
```
 
Convert the JSON string returned by the TDAmeritradeAPI instruments API calls to a DataFrame.
 
An ErrorTypes.jl Option object will be returned that can be evaluated with ErrorTypes.@?
 
# Example
```julia
parseInstrumentsJSONToDataFrame(read("./test/sample/instrument_equity.json", String), "get")
some(1x6 DataFrame
 Row | bondPrice  cusip      symbol  description              exchange  assetType
     | Nothing    String     String  String                   String    String
 --------------------------------------------------------------------------------
   1 |            18915M107  NET     CLOUDFLARE INC COM CL A  EQY       EQUITY)
```
"""
function parseInstrumentsJSONToDataFrame(json_string::String, api_call::String)::ErrorTypes.Option{DataFrame}
    @argcheck api_call in ["get", "search"]
    
    _instrumentJSONToDataFrame(json_string, api_call == "get" ? "array" : "dict")
end
