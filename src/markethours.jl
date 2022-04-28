################################################################################
##
## Define known valid input values for the API call
##
################################################################################
validMarkets = ["EQUITY", "OPTION", "FUTURE", "BOND", "FOREX"];

################################################################################
##
## Define Julia structs to hold the return of the API call
##
################################################################################
struct SessionHours
    product::String
    session::String
    startTime::DateTime
    endTime::DateTime
end

struct Market
    date::String
    marketType::String
    exchange::Union{String, Nothing}
    category::Union{String, Nothing}
    product::String
    productName::Union{String, Nothing}
    isOpen::Bool
end

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
function _getMarketHours(market::String, apiKeys::apiKeys, marketDate::Date=today() + Dates.Day(1))
    @argcheck marketDate >= today()
    @argcheck market in validMarkets

    queryParams = ["{market}" => market]

    bodyParams = Dict{String, Union{Int64, String, Bool}}("date"   => string(marketDate),
                                                          "apikey" => apiKeys.custKey);

    res = doHTTPCall("get_market_hours_for_single_market", queryParams = queryParams, bodyParams = bodyParams);

    if haskey(res, :code) && res[:code] != 200
        res[:body] = haskey(marketHoursHTTPErrorMsg, res[:code]) ? marketHoursHTTPErrorMsg[res[:code]] * ". Market: " * market : "Invalid API Call for market " * market;
    end

    return(res)
end

function _getMarketHours(markets::Vector{String}, apiKeys::apiKeys, marketDate::Date=today() + Dates.Day(1))
    @argcheck marketDate >= today()
    @argcheck length(markets) == length(intersect(markets, validMarkets))
    
    bodyParams = Dict{String, Union{Int64, String, Bool}}("date"    => string(marketDate),
                                                          "markets" => join(markets, ","),
                                                          "apikey"  => apiKeys.custKey);

    res = doHTTPCall("get_market_hours_for_multiple_markets", bodyParams = bodyParams);

    if haskey(res, :code) && res[:code] != 200
        res[:body] = haskey(marketHoursHTTPErrorMsg, res[:code]) ? marketHoursHTTPErrorMsg[res[:code]] * ". Markets: " * join(markets, ",") : "Invalid API Call for market " * join(markets, ",");
    end

    return(res)
end

###############################################################################
##
##  Market Hours - Function signiatures to return the JSON return as a String
##
###############################################################################
function api_getMarketHoursRaw(market::String, apiKeys::apiKeys, marketDate::Date=today() + Dates.Day(1))

    httpRet = _getMarketHours(market, apiKeys, marketDate);

    return(httpRet)
end

function api_getMarketHoursRaw(markets::Vector{String}, apiKeys::apiKeys, marketDate::Date=today() + Dates.Day(1))

    httpRet = _getMarketHours(markets, apiKeys, marketDate);

    return(httpRet)
end

###############################################################################
##
##  Quotes - Function signiatures to return DataFrames
##
###############################################################################
function api_getMarketHoursDF(market::String, apiKeys::apiKeys, marketDate::Date=today() + Dates.Day(1))::DataFrame

    httpRet = _getMarketHours(market, apiKeys, marketDate);

    if haskey(httpRet, :code) && httpRet[:code] == 200
        ljson = LazyJSON.value(httpRet[:body])

        if length(ljson) > 0 && haskey(ljson, lowercase(market))
            df = marketHoursToDataFrame(ljson)
        else
            df = DataFrame([:httpCode => httpRet[:code], :httpMessage => httpRet[:message], :results => "No Market Hours data found for market: " * market])
        end
    else
        df = DataFrame([:httpCode => httpRet[:code], :httpMessage => httpRet[:message], :results => httpRet[:body]])
    end
    
    return(df);
end

function api_getMarketHoursDF(markets::Vector{String}, apiKeys::apiKeys, marketDate::Date=today() + Dates.Day(1))::DataFrame
    
    httpRet = _getMarketHours(markets, apiKeys, marketDate);

    if haskey(httpRet, :code) && httpRet[:code] == 200
        ljson = LazyJSON.value(httpRet[:body])

        if length(ljson) > 0 && haskey(ljson, lowercase(markets[1]))
            df = marketHoursToDataFrame(ljson)
        else
            df = DataFrame([:httpCode => httpRet[:code], :httpMessage => httpRet[:message], :results => "No Market Hours data found for markets: " * join(market, ",")])
        end
    else
        df = DataFrame([:httpCode => httpRet[:code], :httpMessage => httpRet[:message], :results => httpRet[:body]])
    end
    
    return(df);
end

################################################################################
##
##  MarketHours to DataFrame format conversion functions
##
################################################################################
function marketHoursToDataFrame(ljson::LazyJSON.Object{Nothing, String})::DataFrame
    dateFmt     = Dates.DateFormat("yyyy-mm-dd");
    dateTimeFmt = Dates.DateFormat("yyyy-mm-ddTHH:MM:SSzzzz");

    sessionTypes = ["preMarket", "regularMarket", "postMarket", "outcryMarket"]

    vecMarket = Vector{Market}()
    vecHours  = Vector{SessionHours}()
    for k::String in keys(ljson)
        for (ky, vy) in ljson[k]
            push!(vecMarket, convert(Market, vy))
    
            if !isnothing(vy["sessionHours"])
                if haskey(vy["sessionHours"], "preMarket")
                    push!(vecHours, SessionHours(ky, "preMarket", DateTime(ZonedDateTime(String(vy["sessionHours"]["preMarket"][1]["start"]), dateTimeFmt)), 
                                                                  DateTime(ZonedDateTime(String(vy["sessionHours"]["preMarket"][1]["end"]), dateTimeFmt))))
                end
                
                if haskey(vy["sessionHours"], "regularMarket")
                    push!(vecHours, SessionHours(ky, "regularMarket", DateTime(ZonedDateTime(String(vy["sessionHours"]["regularMarket"][1]["start"]), dateTimeFmt)), 
                                                                      DateTime(ZonedDateTime(String(vy["sessionHours"]["regularMarket"][1]["end"]), dateTimeFmt))))
                end
                
                if haskey(vy["sessionHours"], "postMarket")
                    push!(vecHours, SessionHours(ky, "postMarket", DateTime(ZonedDateTime(String(vy["sessionHours"]["postMarket"][1]["start"]), dateTimeFmt)), 
                                                                   DateTime(ZonedDateTime(String(vy["sessionHours"]["postMarket"][1]["end"]), dateTimeFmt))))
                end
    
                if haskey(vy["sessionHours"], "outcryMarket")
                    push!(vecHours, SessionHours(ky, "outcryMarket", DateTime(ZonedDateTime(String(vy["sessionHours"]["outcryMarket"][1]["start"]), dateTimeFmt)), 
                                                                     DateTime(ZonedDateTime(String(vy["sessionHours"]["outcryMarket"][1]["end"]), dateTimeFmt))))
                end
            end
        end
    end
    
    df = leftjoin(DataFrame(vecMarket, copycols = false), DataFrame(vecHours, copycols = false), on = :product)

    @transform! df begin
        :date = Date.(:date, dateFmt)
    end

    @transform! df begin
        :dayName = Dates.dayname.(:date)
    end

    return(df)
end