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
function api_getMarketHoursAsJSON(market::String, apiKeys::apiKeys; marketDate::Date=Dates.dayofweek(today()) >= 6 ? today() + Dates.Day(8-Dates.dayofweek(today())) : today())::ErrorTypes.Result{String, String}
    @argcheck marketDate >= today()
    @argcheck market in validMarkets

    _getMarketHours(market, apiKeys, marketDate);
end


function api_getMarketHoursAsJSON(markets::Vector{String}, apiKeys::apiKeys; marketDate::Date=Dates.dayofweek(today()) >= 6 ? today() + Dates.Day(8-Dates.dayofweek(today())) : today())::ErrorTypes.Result{String, String}
    @argcheck marketDate >= today()
    @argcheck length(markets) == length(intersect(markets, validMarkets))

    _getMarketHours(markets, apiKeys, marketDate);
end

###############################################################################
##
##  MarketHours - Function signiatures to return DataFrames
##
###############################################################################
function api_getMarketHoursAsDataFrame(market::String, apiKeys::apiKeys, marketDate::Date=Dates.dayofweek(today()) >= 6 ? today() + Dates.Day(8-Dates.dayofweek(today())) : today())::ErrorTypes.Option{DataFrame}
    @argcheck marketDate >= today()
    @argcheck market in validMarkets

    httpRet = _getMarketHours(market, apiKeys, marketDate);

    _marketHoursToDataFrame(ErrorTypes.@?(httpRet))
end

function api_getMarketHoursAsDataFrame(markets::Vector{String}, apiKeys::apiKeys, marketDate::Date=Dates.dayofweek(today()) >= 6 ? today() + Dates.Day(8-Dates.dayofweek(today())) : today())::ErrorTypes.Option{DataFrame}
    @argcheck marketDate >= today()
    @argcheck length(markets) == length(intersect(markets, validMarkets))
    
    httpRet = _getMarketHours(markets, apiKeys, marketDate);

    _marketHoursToDataFrame(ErrorTypes.@?(httpRet))
end

###############################################################################
##
##  Convert JSON to Struct
##
###############################################################################
function marketHoursToMarketTypesStruct(json_string::String)::ErrorTypes.Option{MarketTypes}
    some(JSON3.read(json_string, MarketTypes))
end

###############################################################################
##
##  Convert Struct to JSON
##
###############################################################################
function marketHoursToJSON(m::MarketTypes)::ErrorTypes.Option{String}
    some(JSON3.write(m))
end

################################################################################
##
##  MarketHours to DataFrame format conversion functions
##
################################################################################
function parseMarketHoursJSONToDataFrame(json_string::String)::ErrorTypes.Option{DataFrame}
    _marketHoursToDataFrame(json_string)
end
