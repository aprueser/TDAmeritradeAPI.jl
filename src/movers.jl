################################################################################
##
## Define Julia structs to hold the return of the API call
##
################################################################################
mutable struct Mover
    change::Float64
    description::String
    direction::String
    last::Float64
    symbol::String
    totalVolume::Int64

    Mover() = new()
end

StructTypes.StructType(::Type{Mover}) = StructTypes.Mutable();
StructTypes.idproperty(::Type{Mover}) = :symbol

mutable struct Movers <: AbstractArray{Mover, 1}
    movers::Vector{Mover}        
end                              
                                 
Base.getindex(m::Movers, i::Int) = getindex(m.movers, i)
Base.size(m::Movers)             = size(m.movers)

StructTypes.StructType(::Type{Movers}) = StructTypes.ArrayType();

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
function _getMovers(index::String, direction::String, change::String, apiKeys::TDAmeritradeAPI.apiKeys)::ErrorTypes.Result{String, String}
    @argcheck index in ["\$COMPX", "\$DJI", "\$SPX.X"]
    @argcheck direction in ["up", "down"]
    @argcheck change in ["percent", "value"]

    queryParams = ["{index}" => index]

    bodyParams = Dict{String, Union{Number, String, Bool}}("direction" => direction,
                                                          "change"    => change,
                                                          "apikey"    => apiKeys.custKey);

    doHTTPCall("get_movers", queryParams = queryParams, bodyParams = bodyParams);
end

################################################################################
##
##  Movers to DataFrame format conversion function
##
#################################################################################
function _moversJSONToDataFrame(rawJSON::String)::ErrorTypes.Option{DataFrame}
    m::Movers = ErrorTypes.@?(moversToMoversStruct(rawJSON))

    some(DataFrame(m, copycols = false))
end

###############################################################################
##
##  Quotes - Function signiatures to return the JSON return as a String
##
###############################################################################
function api_getMoversAsJSON(index::String, direction::String, change::String, apiKeys::TDAmeritradeAPI.apiKeys)::ErrorTypes.Result{String, String}
    @argcheck index in ["\$COMPX", "\$DJI", "\$SPX.X"]
    @argcheck direction in ["up", "down"]
    @argcheck change in ["percent", "value"]
    
    _getMovers(index, direction, change, apiKeys);

end

###############################################################################
##
##  Movers - Function signiatures to return DataFrames
##
###############################################################################
function api_getMoversAsDataFrame(index::String, direction::String, change::String, apiKeys::TDAmeritradeAPI.apiKeys)::ErrorTypes.Option{DataFrame}

    httpRet = _getMovers(index, direction, change, apiKeys);

    _moversJSONToDataFrame(ErrorTypes.@?(httpRet))
end

###############################################################################
##
##  Convert JSON to Struct
##
###############################################################################
function moversToMoversStruct(json_string::String)::ErrorTypes.Option{Movers}
    some(JSON3.read(json_string, Movers))
end

###############################################################################
##
##  Convert Struct to JSON
##
###############################################################################
function moversToJSON(m::Movers)::ErrorTypes.Option{String}
    some(JSON3.write(m))
end

function parseMoversJSONToDataFrame(json_string::String)::ErrorTypes.Option{DataFrame}
    _moversJSONToDataFrame(json_string)
end

