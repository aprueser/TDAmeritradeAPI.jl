################################################################################
##
## Define Julia structs to hold the return of the API call
##
################################################################################ 
mutable struct QuoteStruct
    assetType::String
    assetMainType::String
    cusip::Union{String, Nothing}
    assetSubType::String        
    symbol::String             
    description::String       
    product::String          
    tick::Float64           
    tickAmount::Float64    
    bidPrice::Float64     
    bidSize::Int64       
    bidId::String       
    bidTick::String    
    askPrice::Float64 
    askSize::Int64   
    askId::String   
    lastPrice::Float64             
    lastSize::Int64
    lastId::String
    openPrice::Float64
    highPrice::Float64
    lowPrice::Float64
    closePrice::Float64
    netChange::Float64
    totalVolume::Int64
    quoteTimeInLong::Int64
    tradeTimeInLong::Int64
    mark::Float64
    exchange::String
    exchangeName::String
    marginable::Bool
    shortable::Bool
    digits::Int32
    tradingHours::String
    isTradable::Bool
    marketMaker::String
    openInterest::Float64
    volatility::Float64
    moneyIntrinsicValue::Float64
    multiplier::Float64
    strikePrice::Float64
    contractType::String
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
    theoreticalOptionValue::Float64
    underlying::String
    underlyingPrice::Float64
    expirationType::String
    lastTradingDay::Int64
    settlementType::String
    impliedYield::Float64
    fiftyTwoWkHigh::Float64 
    fiftyTwoWkLow::Float64 
    nAV::Float64
    peRatio::Float64
    divAmount::Float64
    divYield::Float64
    divDate::String
    securityStatus::String
    regularMarketLastPrice::Float64
    regularMarketLastSize::Int32
    regularMarketNetChange::Float64
    regularMarketTradeTimeInLong::Int64
    netPercentChangeInDouble::Float64
    markChangeInDouble::Float64
    markPercentChangeInDouble::Float64
    regularMarketPercentChangeInDouble::Float64
    futureIsTradable::Bool
    futureTradingHours::String
    futurePercentChange::Float64
    futurePriceFormat::String
    futureSettlementPrice::Float64
    futureMultiplier::Float64
    futureIsActive::Bool
    futureActiveSymbol::String
    futureExpirationDate::Int64
    exerciseType::String
    inTheMoney::Bool
    isPennyPilot::Bool
    delayed::Bool
    realtimeEntitled::Bool

    QuoteStruct() = new(Tuple(fieldtype(QuoteStruct, x) == String ? "" : 
                              fieldtype(QuoteStruct, x) in [Int32, Int64, Float64] ? 0 : 
                              fieldtype(QuoteStruct, x) == Bool ? false : nothing for x in fieldnames(QuoteStruct))...)
end
StructTypes.StructType(::Type{QuoteStruct}) = StructTypes.Mutable();
StructTypes.idproperty(::Type{QuoteStruct}) = :symbol
StructTypes.names(::Type{QuoteStruct}) = ((:fiftyTwoWkHigh, Symbol("52WkHigh")), (:fiftyTwoWkLow, Symbol("52WkLow")), 
                                          (:fiftyTwoWkHigh, Symbol("52WkHighInDouble")), (:fiftyTwoWkLow, Symbol("52WkLowInDouble")),
                                          (:netPercentChangeInDouble, :percentChange), (:netChange, :changeInDouble), (:netChange, :netChangeInDouble), 
                                          (:bidPrice, :bidPriceInDouble), (:askPrice, :askPriceInDouble), (:lastPrice, :lastPriceInDouble),
                                          (:bidSize, :bidSizeInLong), (:askSize, :askSizeInLong), (:lastSize, :lastSizeInLong),
                                          (:highPrice, :highPriceInDouble), (:lowPrice, :lowPriceInDouble), (:closePrice, :closePriceInDouble),
                                          (:openPrice, :openPriceInDouble), (:expirationType, :uvExpirationType), (:delta, :deltaInDouble),
                                          (:gamma, :gammaInDouble), (:theta, :thetaInDouble), (:vega, :vegaInDouble), (:rho, :rhoInDouble),
                                          (:timeValue, :timeValueInDouble), (:moneyIntrinsicValue, :moneyIntrinsicValueInDouble), 
                                          (:multiplier, :multiplierInDouble), (:strikePrice, :strikePriceInDouble))

mutable struct QuoteArray <: AbstractArray{QuoteStruct, 1}
    quotes::Vector{QuoteStruct}
end

Base.getindex(qt::QuoteArray, i::Int) = getindex(qt.quotes, i)
Base.size(qt::QuoteArray)             = size(qt.quotes)

StructTypes.StructType(::Type{QuoteArray}) = StructTypes.ArrayType();

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
function _getQuote(symbol::String, apiKeys::TDAmeritradeAPI.apiKeys)::ErrorTypes.Result{String, String}
    @argcheck length(strip(symbol)) > 0
    @argcheck startswith(symbol, r"[A-Za-z\$]")

    queryParams = ["{symbol}" => symbol];

    bodyParams = Dict{String, Union{Number, String, Bool}}("apikey" => apiKeys.custKey);

    doHTTPCall("get_quote", queryParams = queryParams, bodyParams = bodyParams);
end

function _getQuotes(symbols::String, apiKeys::TDAmeritradeAPI.apiKeys)::ErrorTypes.Result{String, String}
    @argcheck length(strip.(symbols)) > 0

    bodyParams = Dict{String, Union{Number, String, Bool}}("symbol" => symbols,
                                                          "apikey" => apiKeys.custKey);

    doHTTPCall("get_quotes", bodyParams = bodyParams);
end

################################################################################
##
##  Quotes to DataFrame format conversion functions
##
################################################################################
function _quotesJSONToDataFrame(rawJSON::String)::ErrorTypes.Option{DataFrame}
    q::QuoteArray = ErrorTypes.@?(quotesToQuoteStruct(rawJSON))

    some(DataFrame(q))
end

###############################################################################
##
##  Quotes - Function signiatures to return the JSON return as a String
##
###############################################################################
"""  
```julia
api_getQuoteAsJSON(symbol::String, apiKeys::TDAmeritradeAPI.apiKeys)::ErrorTypes.Result{String, String}
```  
     
Make the TDAmeritradeAPI call to the get\\_quote endpoint, and return the raw JSON.
     
An ErrorTypes.jl Option object will be returned that can be evaluated with ErrorTypes.@?
 
# Arguments
- `symbol::String`: The ticker symbol to fetch a quote for
- `apiKeys::TDAmeritradeAPI.apiKeys`: the apiKeys object containing the CUST_KEY, access
    and refresh tokens.
 
# Example
```julia
api_getQuoteAsJSON("NET", apiKey)
Result{String, String}(Ok("{\"NET\":{\"assetType\":\"EQUITY\",\"assetMainType\":\"EQUITY\",\"cusip\":\"18915M107\",\"assetSubType\":\"\",\"symbol\":\"NET\"
[...]
```
"""
function api_getQuoteAsJSON(symbol::String, apiKeys::TDAmeritradeAPI.apiKeys)::ErrorTypes.Result{String, String}
     _getQuote(symbol, apiKeys);
end

"""  
```julia
api_getQuotesAsJSON(symbols::Vector{String}, apiKeys::TDAmeritradeAPI.apiKeys)ErrorTypes.Result{String, String}
```  
     
Make the TDAmeritradeAPI call to the get\\_quotes endpoint, and return the raw JSON.
     
An ErrorTypes.jl Option object will be returned that can be evaluated with ErrorTypes.@?
 
# Arguments
- `symbols::Vector{String}`: A Vector of ticker symbols to fetch a quotes for
- `apiKeys::TDAmeritradeAPI.apiKeys`: the apiKeys object containing the CUST_KEY, access
    and refresh tokens.
 
# Example
```julia
api_getQuotesAsJSON(["NET", "PANW", "ZS"], apiKey)
Result{String, String}(Ok("{\"NET\":{\"assetType\":\"EQUITY\",\"assetMainType\":\"EQUITY\",\"cusip\":\"18915M107\",\"assetSubType\":\"\",\"symbol\":\"NET\" ...
                            \"PANW\":{\"assetType\":\"EQUITY\",\"assetMainType\":\"EQUITY\",\"cusip\":\"697435105\",\"assetSubType\":\"\",\"symbol\":\"PANW\" ...
[...]
```
"""
function api_getQuotesAsJSON(symbols::Vector{String}, apiKeys::TDAmeritradeAPI.apiKeys)ErrorTypes.Result{String, String}
    _getQuotes(join(symbols, ","), apiKeys);
end

"""
```julia
api_getQuotesAsJSON(symbols::String, apiKeys::TDAmeritradeAPI.apiKeys)ErrorTypes.Result{String, String}
```

Make the TDAmeritradeAPI call to the get\\_quotes endpoint, and return the raw JSON.

An ErrorTypes.jl Option object will be returned that can be evaluated with ErrorTypes.@?

# Arguments
- `symbols::String`: A comma separated string of ticker symbols to fetch a quotes for
- `apiKeys::TDAmeritradeAPI.apiKeys`: the apiKeys object containing the CUST_KEY, access
    and refresh tokens.

# Example
```julia
api_getQuotesAsJSON("NET,PANW,ZS", apiKey)
Result{String, String}(Ok("{\"NET\":{\"assetType\":\"EQUITY\",\"assetMainType\":\"EQUITY\",\"cusip\":\"18915M107\",\"assetSubType\":\"\",\"symbol\":\"NET\" ...
                            \"PANW\":{\"assetType\":\"EQUITY\",\"assetMainType\":\"EQUITY\",\"cusip\":\"697435105\",\"assetSubType\":\"\",\"symbol\":\"PANW\" ...
[...]
```
"""
function api_getQuotesAsJSON(symbols::String, apiKeys::TDAmeritradeAPI.apiKeys)ErrorTypes.Result{String, String}
    _getQuotes(symbols, apiKeys);
end

###############################################################################
##
##  Quotes - Function signiatures to return DataFrames
##
###############################################################################
"""                           
```julia                      
api_getQuoteAsDataFrame(symbol::String, apiKeys::TDAmeritradeAPI.apiKeys)ErrorTypes.Result{String, String}
```                           
 
Make the TDAmeritradeAPI call to the get\\_quote endpoint, and return a DataFrame
 
An ErrorTypes.jl Option object will be returned that can be evaluated with ErrorTypes.@?
 
# Arguments                   
- `symbol::String`: The ticker symbol to fetch a quote for
- `apiKeys::TDAmeritradeAPI.apiKeys`: the apiKeys object containing the CUST_KEY, access
    and refresh tokens.       
 
# Example                     
```julia                      
api_getQuoteAsDataFrame("NET", apiKey) 
some(1x90 DataFrame
 Row | assetType  assetMainType  cusip      assetSubType  symbol  description ...
     | String     String         String     String        String  String     
 ------------------------------------------------------------------------------------------------
   1 | EQUITY     EQUITY         18915M107                NET     Cloudflare, Inc. Class A Common
[...]                         
```                           
"""
function api_getQuoteAsDataFrame(symbol::String, apiKeys::TDAmeritradeAPI.apiKeys)::ErrorTypes.Option{DataFrame}
    httpRet = _getQuote(symbol, apiKeys);

    _quotesJSONToDataFrame(ErrorTypes.@?(httpRet))
end

"""
```julia
api_getQuotesAsDataFrame(symbols::Vector{String}, apiKeys::TDAmeritradeAPI.apiKeys)ErrorTypes.Result{String, String}
```

Make the TDAmeritradeAPI call to the get\\_quotes endpoint, and return a DataFrame

An ErrorTypes.jl Option object will be returned that can be evaluated with ErrorTypes.@?

# Arguments
- `symbols::Vector{String}`: A Vector of ticker symbols to fetch a quotes for
- `apiKeys::TDAmeritradeAPI.apiKeys`: the apiKeys object containing the CUST_KEY, access
    and refresh tokens.

# Example
```julia
api_getQuotesAsJSON(["NET", "PANW", "ZS"], apiKey)
some(3x90 DataFrame
 Row | assetType  assetMainType  cusip      assetSubType  symbol  description ...
     | String     String         String     String        String  String      
 -------------------------------------------------------------------------------------------------
   1 | EQUITY     EQUITY         18915M107                NET     Cloudflare, Inc. Class A Common 
   2 | EQUITY     EQUITY         697435105                PANW    Palo Alto Networks, Inc. - Commo
   3 | EQUITY     EQUITY         98980G102                ZS      Zscaler, Inc. - Common Stock
[...]
```
"""
function api_getQuotesAsDataFrame(symbols::Vector{String}, apiKeys::TDAmeritradeAPI.apiKeys)::ErrorTypes.Option{DataFrame}
    api_getQuotesAsDataFrame(join(symbols, ","), apiKeys);
end

"""
```julia
api_getQuotesAsDataFrame(symbols::String, apiKeys::TDAmeritradeAPI.apiKeys)ErrorTypes.Result{String, String}
```

Make the TDAmeritradeAPI call to the get\\_quotes endpoint, and return a DataFrame

An ErrorTypes.jl Option object will be returned that can be evaluated with ErrorTypes.@?

# Arguments
- `symbols::String`: A comma separated string of ticker symbols to fetch a quotes for
- `apiKeys::TDAmeritradeAPI.apiKeys`: the apiKeys object containing the CUST_KEY, access
    and refresh tokens.

# Example
```julia
api_getQuotesAsJSON("NET,PANW,ZS", apiKey)
some(3x90 DataFrame
 Row | assetType  assetMainType  cusip      assetSubType  symbol  description ...
     | String     String         String     String        String  String      
 -------------------------------------------------------------------------------------------------
   1 | EQUITY     EQUITY         18915M107                NET     Cloudflare, Inc. Class A Common 
   2 | EQUITY     EQUITY         697435105                PANW    Palo Alto Networks, Inc. - Commo
   3 | EQUITY     EQUITY         98980G102                ZS      Zscaler, Inc. - Common Stock
[...]
```
"""
function api_getQuotesAsDataFrame(symbols::String, apiKeys::TDAmeritradeAPI.apiKeys)::ErrorTypes.Option{DataFrame}
    httpRet = _getQuotes(symbols, apiKeys);

    _quotesJSONToDataFrame(ErrorTypes.@?(httpRet))
end

###############################################################################
##
##  Convert JSON to Struct
##
###############################################################################
"""                                                                                                                                                                                                                
```julia
quotesToQuoteStruct(json_string::String)::ErrorTypes.Option{QuoteArray}
```    
   
Convert the JSON string returned by a TDAmeritradeAPI get\\_quote(s) API calls to a QuoteArray struct.
       
This is largely an internal function to allow later conversions to DataFrame with proper type conversions.
       
An ErrorTypes.jl Option object will be returned that can be evaluated with ErrorTypes.@?
       
# Example 
```julia 
quotesToQuoteStruct(j)
some(TDAmeritradeAPI.QuoteStruct[TDAmeritradeAPI.QuoteStruct("EQUITY", "EQUITY", "18915M107", "", "NET", "Cloudflare, Inc. Class A Common Stock", ...
TDAmeritradeAPI.QuoteStruct("EQUITY", "EQUITY", "697435105", "", "PANW", "Palo Alto Networks, Inc. - Common Stock", ...
TDAmeritradeAPI.QuoteStruct("EQUITY", "EQUITY", "98980G102", "", "ZS", "Zscaler, Inc. - Common Stock", ...
[...]  
```  
"""
function quotesToQuoteStruct(json_string::String)::ErrorTypes.Option{QuoteArray}
    j3 = JSON3.read(json_string)

    retArray = Vector{Any}()
    for (k, v) in j3
        push!(retArray, v)
    end

    some(StructTypes.constructfrom(QuoteArray, retArray))
end

###############################################################################
##
##  Convert Struct to JSON
##
###############################################################################
"""
```julia
quotesToJSON(q::QuoteArray)::ErrorTypes.Option{String}
```
  
Convert a QuoteArray struct q to a JSON object.
  
An ErrorTypes.jl Option object will be returned that can be evaluated with ErrorTypes.@?
  
The returned JSON will not be in the same format as the initial return from the TDAmeritradeAPI call.
  
# Example
```julia
quotesToJSON(s)
some("[{\"assetType\":\"EQUITY\",\"assetMainType\":\"EQUITY\",\"cusip\":\"18915M107\",\"assetSubType\":\"\",\"symbol\":\"NET\",\"description\":\"Cloudflare, Inc. Class A Common Stock\"
[...]
```
"""
function quotesToJSON(q::QuoteArray)::ErrorTypes.Option{String}
    some(JSON3.write(q))
end


################################################################################
##
##  Quotes JSON to DataFrame format conversion functions
##
################################################################################
"""
```julia
parseQuotesJSONToDataFrame(json_string::String)::ErrorTypes.Option{DataFrame}
```

Convert the JSON string returned by a TDAmeritradeAPI get\\_quote(s) API call to a DataFrame.

Nested JSON objects will be flattened into columns in the output DataFrame.

An ErrorTypes.jl Option object will be returned that can be evaluated with ErrorTypes.@?

# Example
```julia
parseQuotesJSONToDataFrame(j)
some(3x90 DataFrame
 Row | assetType  assetMainType  cusip      assetSubType  symbol  description ...
     | String     String         String     String        String  String      
 -------------------------------------------------------------------------------------------------
   1 | EQUITY     EQUITY         18915M107                NET     Cloudflare, Inc. Class A Common 
   2 | EQUITY     EQUITY         697435105                PANW    Palo Alto Networks, Inc. - Commo
   3 | EQUITY     EQUITY         98980G102                ZS      Zscaler, Inc. - Common Stock
[...]
```
"""
function parseQuotesJSONToDataFrame(json_string::String)::ErrorTypes.Option{DataFrame}
     _quotesJSONToDataFrame(json_string)
end

