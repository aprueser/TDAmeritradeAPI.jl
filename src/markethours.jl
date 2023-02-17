################################################################################
##
## Define known valid input values for the API call
##
################################################################################
validMarkets = ["EQUITY", "OPTION", "FUTURE", "BOND", "FOREX"];
sessionTypes = ["preMarket", "regularMarket", "postMarket", "outcryMarket"]

################################################################################
##
## Define Julia structs to hold the return of the API call
##
################################################################################

mutable struct SessionHours
      start::String
      finish::String

      SessionHours() = new()
end
StructTypes.StructType(::Type{SessionHours}) = StructTypes.Mutable();
StructTypes.names(::Type{SessionHours}) = ((:finish, :end),);

mutable struct Sessions
      preMarket::Array{SessionHours, 1}
      regularMarket::Array{SessionHours, 1}
      postMarket::Array{SessionHours, 1}
      outcryMarket::Array{SessionHours, 1}

      Sessions() = new()
end
StructTypes.StructType(::Type{Sessions}) = StructTypes.Mutable();

mutable struct Market
      date::Date
      marketType::Union{String, Nothing}
      exchange::Union{String, Nothing}
      category::Union{String, Nothing}
      product::Union{String, Nothing}
      productName::Union{String, Nothing}
      isOpen::Bool
      sessionHours::Union{Sessions, Nothing}

      Market() = new()
end
StructTypes.StructType(::Type{Market}) = StructTypes.Mutable();

mutable struct MarketTypes
    equity::Dict{String, Market}
    option::Dict{String, Market}
    future::Dict{String, Market}
    bond::Dict{String, Market}
    forex::Dict{String, Market}

    MarketTypes() = new()
end
StructTypes.StructType(::Type{MarketTypes}) = StructTypes.Mutable();

################################################################################
##
## Define custom HTTP error messages for the API call
##
################################################################################
marketHoursHTTPErrorMsg = Dict{Int64, String}(
    401 => "Unauthorized",
    403 => "Forbidden",
    404 => "Not Found."
)

################################################################################
##
##  MarketHours - Core API Call Functions
##
################################################################################
function _getMarketHours(market::String, apiKeys::apiKeys, marketDate::Date=today() + Dates.Day(1))::ErrorTypes.Result{String, String}
    @argcheck marketDate >= today()
    @argcheck market in validMarkets

    queryParams = ["{market}" => market]

    bodyParams = Dict{String, Union{Number, String, Bool}}("date"   => string(marketDate),
                                                          "apikey" => apiKeys.custKey);

    doHTTPCall("get_market_hours_for_single_market", queryParams = queryParams, bodyParams = bodyParams);
end

function _getMarketHours(markets::Vector{String}, apiKeys::apiKeys, marketDate::Date=today() + Dates.Day(1))::ErrorTypes.Result{String, String}
    @argcheck marketDate >= today()
    @argcheck length(markets) == length(intersect(markets, validMarkets))
    
    bodyParams = Dict{String, Union{Number, String, Bool}}("date"    => string(marketDate),
                                                           "markets" => join(markets, ","),
                                                           "apikey"  => apiKeys.custKey);

    doHTTPCall("get_market_hours_for_multiple_markets", bodyParams = bodyParams);
end

################################################################################
##
## Flatten the structs to a DataFrame
##
################################################################################
function _marketSessionStructToDataFrame(type::String, product::String, s::Sessions)::ErrorTypes.Option{DataFrame}
    dateTimeFmt = Dates.DateFormat("yyyy-mm-ddTHH:MM:SSzzzz");

    sess = DataFrame(marketType = type, product = product)
    for vs in sessionTypes
        tupleNames = (:marketType, :product, Symbol(vs * "_openDateTime"), Symbol(vs * "_closeDateTime"));
        if isdefined(s, Symbol(vs))
            sh = getproperty(s, Symbol(vs))[1]
            tupleValues = (type, product, DateTime(sh.start, dateTimeFmt), DateTime(sh.finish, dateTimeFmt))
        else    
            tupleValues = (type, product, nothing, nothing);
        end     
       
        # Join the sessions into a single horizontal row
        sess = innerjoin(sess, DataFrame([NamedTuple{tupleNames, Tuple{String, String, Union{DateTime, Nothing}, Union{DateTime, Nothing}}}(tupleValues)]), on = [:marketType, :product])
    end         
                
    some(sess)        
end             
                
function _marketTypesStructToDataFrame(s::MarketTypes)::ErrorTypes.Option{DataFrame}
    mkts::Union{DataFrame, Nothing} = nothing
    for mkt in lowercase.(validMarkets)
        if isdefined(s, Symbol(mkt))                                                                                                                                                                                             
            for v in values(getproperty(s, Symbol(mkt)))
                shdf = isdefined(v, :sessionHours) && !isnothing(v.sessionHours) ? ErrorTypes.@?(_marketSessionStructToDataFrame(v.marketType, v.product, v.sessionHours)) : DataFrame(marketType = v.marketType, product = v.product)
                mktdf = leftjoin(DataFrame([v]), shdf, on = [:marketType, :product])
                select!(mktdf, Not(:sessionHours))
                
                mkts = isnothing(mkts) ? mktdf : vcat(mkts, mktdf, cols = :union)
            end 
        end 
    end  
                
    some(mkts)        
end 

################################################################################
##
##  Market HourMarket Hours to DataFrame format conversion function
##
#################################################################################
function _marketHoursJSONToDataFrame(rawJSON::String)::ErrorTypes.Option{DataFrame}
    mt::MarketTypes = ErrorTypes.@?(marketHoursToMarketTypesStruct(rawJSON))

    _marketTypesStructToDataFrame(mt)
end

###############################################################################
##
##  Market Hours - Function signiatures to return the JSON return as a String
##
###############################################################################
"""  
```julia
api_getMarketHoursAsJSON(market::String, apiKeys::apiKeys; kw...)::ErrorTypes.Result{String, String}
```  
     
Make the TDAmeritradeAPI call to the get\\_market\\_hours\\_for\\_single\\_market endpoint, and return the raw JSON.
     
An ErrorTypes.jl Option object will be returned that can be evaluated with ErrorTypes.@?

# Arguments
- `market::String`: The market to get hours for. Valid values are:
   - "EQUITY"
   - "OPTION"
   - "FUTURE"
   - "BOND"
   - "FOREX"
- `apiKeys::TDAmeritradeAPI.apiKeys`: the apiKeys object containing the CUST_KEY, access
    and refresh tokens.

# Keywords
- `marketDate::Date`: Date to fetch the market hours for. Default to today(), unless today is a 
    weekend, then the next Monday.

# Example
```julia
api_getMarketHoursAsJSON("EQUITY", apiKey)
Result{String, String}(Ok("{\"equity\":{\"EQ\":{\"date\":\"2023-02-17\",\"marketType\":\"EQUITY\",\"exchange\":\"NULL\",\"category\":\"NULL\",\"product\":\"EQ\"
[...]
```
"""
function api_getMarketHoursAsJSON(market::String, apiKeys::apiKeys; 
                                  marketDate::Date=Dates.dayofweek(today()) >= 6 ? today() + Dates.Day(8-Dates.dayofweek(today())) : today()
                                 )::ErrorTypes.Result{String, String}
    @argcheck marketDate >= today()
    @argcheck market in validMarkets

    _getMarketHours(market, apiKeys, marketDate);
end

"""  
```julia
api_getMarketHoursAsJSON(markets::Vector{String}, apiKeys::apiKeys; kw...)::ErrorTypes.Result{String, String}
```  
     
Make the TDAmeritradeAPI call to the get\\_market\\_hours\\_for\\_multiple\\_markets endpoint, and return the raw JSON.
     
An ErrorTypes.jl Option object will be returned that can be evaluated with ErrorTypes.@?

# Arguments
- `markets::Vector{String}`: A Vector of markets to get hours for. Valid values are:
   - "EQUITY"
   - "OPTION"
   - "FUTURE"
   - "BOND"
   - "FOREX"
- `apiKeys::TDAmeritradeAPI.apiKeys`: the apiKeys object containing the CUST_KEY, access
    and refresh tokens.

# Keywords
- `marketDate::Date`: Date to fetch the market hours for. Default to today(), unless today is a 
    weekend, then the next Monday.

# Example
```julia
api_getMarketHoursAsJSON(["EQUITY", "OPTION"], apiKey)
Result{String, String}(Ok("{\"option\":{\"EQO\":{\"date\":\"2023-02-17\",\"marketType\":\"OPTION\",\"exchange\":\"NULL\",\"category\":\"NULL\",\"product\":\"EQO\"
[...]
```
"""
function api_getMarketHoursAsJSON(markets::Vector{String}, apiKeys::apiKeys; 
                                  marketDate::Date=Dates.dayofweek(today()) >= 6 ? today() + Dates.Day(8-Dates.dayofweek(today())) : today()
                                 )::ErrorTypes.Result{String, String}
    @argcheck marketDate >= today()
    @argcheck length(markets) == length(intersect(markets, validMarkets))

    _getMarketHours(markets, apiKeys, marketDate);
end

###############################################################################
##
##  MarketHours - Function signiatures to return DataFrames
##
###############################################################################
"""  
```julia
api_getMarketHoursAsDataFrame(market::String, apiKeys::apiKeys; kw...)::ErrorTypes.Option{DataFrame}
```  
     
Make the TDAmeritradeAPI call to the get\\_market\\_hours\\_for\\_single\\_market endpoint, and return a DataFrame.
     
An ErrorTypes.jl Option object will be returned that can be evaluated with ErrorTypes.@?

# Arguments
See [`api_getMarketHoursAsJSON(::String, ::apiKeys)`](@ref).

# Keywords
See [`api_getMarketHoursAsJSON(::String, ::apiKeys)`](@ref).

# Example
```julia
api_getMarketHoursAsDataFrame("EQUITY", apiKey)
some(1x15 DataFrame
 Row | date        marketType  exchange  category  product  productName  isOpen  preMarket_openDateTime ...
     | Date        String      String    String    String   String       Bool    Union    
 ----------------------------------------------------------------------------------------------------------
   1 | 2023-02-17  EQUITY      NULL      NULL      EQ       equity         true  2023-02-17T07:00:00    ...
[...]
```
"""
function api_getMarketHoursAsDataFrame(market::String, apiKeys::apiKeys; 
                                       marketDate::Date=Dates.dayofweek(today()) >= 6 ? today() + Dates.Day(8-Dates.dayofweek(today())) : today()
                                      )::ErrorTypes.Option{DataFrame}
    @argcheck marketDate >= today()
    @argcheck market in validMarkets

    httpRet = _getMarketHours(market, apiKeys, marketDate);

    _marketHoursJSONToDataFrame(ErrorTypes.@?(httpRet))
end

"""  
```julia
api_getMarketHoursAsDataFrame(markets::Vector{String}, apiKeys::apiKeys; kw...)::ErrorTypes.Result{String, String}
```  
     
Make the TDAmeritradeAPI call to the get\\_market\\_hours\\_for\\_multiple\\_markets endpoint, and return a DataFrame.
     
An ErrorTypes.jl Option object will be returned that can be evaluated with ErrorTypes.@?

# Arguments
See [`api_getMarketHoursAsJSON(::Vector{String}, ::apiKeys)`](@ref).

# Keywords
See [`api_getMarketHoursAsJSON(::Vector{String}, ::apiKeys)`](@ref).

# Example
```julia
api_getMarketHoursAsDataFrame(["EQUITY", "OPTION"], apiKey)
some(3x15 DataFrame
 Row | date        marketType  exchange  category  product  productName    isOpen  preMarket_openDateTime ...
     | Date        String      String    String    String   String         Bool    Union
 ------------------------------------------------------------------------------------------------------------
   1 | 2023-02-17  EQUITY      NULL      NULL      EQ       equity           true  2023-02-17T07:00:00    ...
   2 | 2023-02-17  OPTION      NULL      NULL      IND      index option     true
[...]
```
"""
function api_getMarketHoursAsDataFrame(markets::Vector{String}, apiKeys::apiKeys; 
                                       marketDate::Date=Dates.dayofweek(today()) >= 6 ? today() + Dates.Day(8-Dates.dayofweek(today())) : today()
                                      )::ErrorTypes.Option{DataFrame}
    @argcheck marketDate >= today()
    @argcheck length(markets) == length(intersect(markets, validMarkets))
    
    httpRet = _getMarketHours(markets, apiKeys, marketDate);

    _marketHoursJSONToDataFrame(ErrorTypes.@?(httpRet))
end

###############################################################################
##
##  Convert JSON to Struct
##
###############################################################################
"""                                                                                                                                                                                                                
```julia
marketHoursToMarketTypesStruct(json_string::String)::ErrorTypes.Option{MarketTypes}
```    
   
Convert the JSON string returned by a TDAmeritradeAPI get\\_market\\_hours... API calls to a MarketTypes struct.
       
This is largely an internal function to allow later conversions to DataFrame with proper type conversions.
       
An ErrorTypes.jl Option object will be returned that can be evaluated with ErrorTypes.@?
       
# Example 
```julia 
marketHoursToMarketTypesStruct(j)
some(TDAmeritradeAPI.MarketTypes(Dict{String, TDAmeritradeAPI.Market}("EQ" => TDAmeritradeAPI.Market(Date("2023-02-17"), "EQUITY"
[...]  
```  
""" 
function marketHoursToMarketTypesStruct(json_string::String)::ErrorTypes.Option{MarketTypes}
    some(JSON3.read(json_string, MarketTypes))
end

###############################################################################
##
##  Convert Struct to JSON
##
###############################################################################
"""
```julia
marketHoursToJSON(m::MarketTypes)::ErrorTypes.Option{String}
```
  
Convert a MarketTypes struct m to a JSON object.
  
An ErrorTypes.jl Option object will be returned that can be evaluated with ErrorTypes.@?
  
The returned JSON will not be in the same format as the initial return from the TDAmeritradeAPI call.
  
# Example
```julia
marketHoursToJSON(s)
some("{\"equity\":{\"EQ\":{\"date\":\"2023-02-17\",\"marketType\":\"EQUITY\",\"exchange\":\"NULL\",\"category\":\"NULL\"
[...]
```
"""
function marketHoursToJSON(m::MarketTypes)::ErrorTypes.Option{String}
    some(JSON3.write(m))
end

################################################################################
##
##  MarketHours to DataFrame format conversion functions
##
################################################################################
"""
```julia
parseMarketHoursJSONToDataFrame(json_string::String)::ErrorTypes.Option{DataFrame}
```
 
Convert the JSON string returned by a TDAmeritradeAPI get\\_market\\_hours... API to a DataFrame.
 
Nested JSON objects will be flattened into columns in the output DataFrame.
 
An ErrorTypes.jl Option object will be returned that can be evaluated with ErrorTypes.@?
 
# Example
```julia
parseMarketHoursJSONToDataFrame(j)
some(3x15 DataFrame
 Row | date        marketType  exchange  category  product  productName    isOpen  preMarket_openDateTime ...
     | Date        String      String    String    String   String         Bool    Union
 ------------------------------------------------------------------------------------------------------------
   1 | 2023-02-17  EQUITY      NULL      NULL      EQ       equity           true  2023-02-17T07:00:00    ...
   2 | 2023-02-17  OPTION      NULL      NULL      IND      index option     true
[...]
```
"""
function parseMarketHoursJSONToDataFrame(json_string::String)::ErrorTypes.Option{DataFrame}
    _marketHoursJSONToDataFrame(json_string)
end
