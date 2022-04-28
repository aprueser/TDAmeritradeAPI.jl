################################################################################
##
## Define Julia structs to hold the return of the API call
##
################################################################################
struct Mover
    change::Float64
    description::String
    direction::String
    last::Float64
    symbol::String
    totalVolume::Int64
end

################################################################################
##
## Define custom HTTP error messages for the API call
##
################################################################################
moversHTTPErrorMsg = Dict{Int64, String}(
    400 => "Must pass a non null value in the parameter",
    401 => "Unauthorized",
    403 => "Forbidden",
    404 => "Movers for the instrument not found."
)

###############################################################
##
##  Movers - Core API Call Functions
##
###############################################################    
function _getMovers(index::String, direction::String, change::String, apiKeys::TDAmeritradeAPI.apiKeys)
    @argcheck index in ["\$COMPX", "\$DJI", "\$SPX.X"]
    @argcheck direction in ["up", "down"]
    @argcheck change in ["percent", "value"]

    queryParams = ["{index}" => index]

    bodyParams = Dict{String, Union{Int64, String, Bool}}("direction" => direction,
                                                          "change"    => change,
                                                          "apikey"    => apiKeys.custKey);

    res = doHTTPCall("get_movers", queryParams = queryParams, bodyParams = bodyParams);

    if haskey(res, :code) && res[:code] != 200
        res[:body] = haskey(moversHTTPErrorMsg, res[:code]) ? moversHTTPErrorMsg[res[:code]] * ". Index: " * index : "Invalid API Call for index " * index;
    end

    return(res)
end

###############################################################################
##
##  Quotes - Function signiatures to return the JSON return as a String
##
###############################################################################
function api_getMoversRaw(index::String, direction::String, change::String, apiKeys::TDAmeritradeAPI.apiKeys)
    
    httpRet = _getMovers(index, direction, change, apiKeys);

    return(httpRet)
end

###############################################################################
##
##  Movers - Function signiatures to return DataFrames
##
###############################################################################
function api_getMoversDF(index::String, direction::String, change::String, apiKeys::TDAmeritradeAPI.apiKeys)::DataFrame

    httpRet = _getMovers(index, direction, change, apiKeys);

    if haskey(httpRet, :code) && httpRet[:code] == 200
        ljson = LazyJSON.value(httpRet[:body])

        if length(ljson) > 0
            df = moversToDataFrame(ljson)
        else
            df = DataFrame([:httpCode => httpRet[:code], :httpMessage => httpRet[:message], :results => "No Movers data found for index: " * index])
        end
    else
        df = DataFrame([:httpCode => httpRet[:code], :httpMessage => httpRet[:message], :results => httpRet[:body]])
    end
    
    return(df);

end

################################################################################
##
##  Movers to DataFrame format conversion functions
##
################################################################################
function moversToDataFrame(ljson::LazyJSON.Array{Nothing, String})::DataFrame

    vec = Vector{Mover}()

    for m in ljson
        mv::Mover = convert(Mover, m)
        push!(vec, mv)
    end

    df = DataFrame(vec, copycols = false)

    return(df)
end