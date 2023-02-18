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
##  Movers - Function signiatures to return the JSON return as a String
##
###############################################################################
"""  
```julia
api_getMoversAsJSON(index::String, direction::String, change::String, apiKeys::TDAmeritradeAPI.apiKeys)::ErrorTypes.Result{String, String}
```  
     
Make the TDAmeritradeAPI call to the get\\_movers endpoint, and return the raw JSON.
     
An ErrorTypes.jl Option object will be returned that can be evaluated with ErrorTypes.@?
 
# Arguments
- `index::String`: The index to get the top 10 movers for. Valid values are:
   - "\$COMPX"
   - "\$DJI"
   - "\$SPX.X"
- `direction`: The direction of the moves to fetch. Valid values are "up" or "down".
- `change`: The measure of the move. Valid values are "percent" or "value".
- `apiKeys::TDAmeritradeAPI.apiKeys`: the apiKeys object containing the CUST_KEY, access
    and refresh tokens.
 
# Example
```julia
api_getMoversAsJSON("\$SPX.X", "up", "percent", apiKey)
Result{String, String}(Ok("[{\"change\":0.14539007092198572,\"description\":\"West Pharmaceutical Services, Inc. Common Stock\",\"direction\":\"up\"
[...]
```
"""
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
"""   
```julia 
api_getMoversAsDataFrame(index::String, direction::String, change::String, apiKeys::TDAmeritradeAPI.apiKeys)::ErrorTypes.Option{DataFrame}
```   
      
Make the TDAmeritradeAPI call to the get\\_movers endpoint, and return a DataFrame.
      
An ErrorTypes.jl Option object will be returned that can be evaluated with ErrorTypes.@?
 
# Arguments 
- `index::String`: The index to get the top 10 movers for. Valid values are:   
   - "\$COMPX" 
   - "\$DJI" 
   - "\$SPX.X" 
- `direction`: The direction of the moves to fetch. Valid values are "up" or "down".
- `change`: The measure of the move. Valid values are "percent" or "value".    
- `apiKeys::TDAmeritradeAPI.apiKeys`: the apiKeys object containing the CUST_KEY, access
    and refresh tokens. 
 
# Example 
```julia 
api_getMoversAsDataFrame("\$SPX.X", "up", "percent", apiKey) 
some(10x6 DataFrame
 Row | change     description                        direction  last     symbol  totalVolume
     | Float64    String                             String     Float64  String  Int64
 -------------------------------------------------------------------------------------------
   1 | 0.14539    West Pharmaceutical Services, In   up          319.77  WST         2034989
   2 | 0.0524252  Cisco Systems, Inc. - Common Sto   up           50.99  CSCO       48125324
   3 | 0.0470325  Albemarle Corporation Common Sto   up          285.62  ALB         3497048
   4 | 0.0405268  Catalent, Inc. Common Stock        up           71.89  CTLT        2572417
[...] 
``` 
"""
function api_getMoversAsDataFrame(index::String, direction::String, change::String, apiKeys::TDAmeritradeAPI.apiKeys)::ErrorTypes.Option{DataFrame}

    httpRet = _getMovers(index, direction, change, apiKeys);

    _moversJSONToDataFrame(ErrorTypes.@?(httpRet))
end

###############################################################################
##
##  Convert JSON to Struct
##
###############################################################################
"""                                                                                                                                                                                                                
```julia
moversToMoversStruct(json_string::String)::ErrorTypes.Option{Movers}
```    
   
Convert the JSON string returned by a TDAmeritradeAPI get\\_movers API calls to a Movers struct.
       
This is largely an internal function to allow later conversions to DataFrame with proper type conversions.
       
An ErrorTypes.jl Option object will be returned that can be evaluated with ErrorTypes.@?
       
# Example 
```julia 
moversToMoversStruct(j)
some(TDAmeritradeAPI.Mover[TDAmeritradeAPI.Mover(0.14539007092198572, "West Pharmaceutical Services, Inc. Common Stock", "up", 319.77, "WST", 2034989), 
     TDAmeritradeAPI.Mover(0.05242518059855519, "Cisco Systems, Inc. - Common Stock", "up", 50.99, "CSCO", 48125324),
[...]  
```  
"""
function moversToMoversStruct(json_string::String)::ErrorTypes.Option{Movers}
    some(JSON3.read(json_string, Movers))
end

###############################################################################
##
##  Convert Struct to JSON
##
###############################################################################
"""
```julia
moversToJSON(m::Movers)::ErrorTypes.Option{String}
```
  
Convert a Movers struct m to a JSON object.
  
An ErrorTypes.jl Option object will be returned that can be evaluated with ErrorTypes.@?
  
The returned JSON will not be in the same format as the initial return from the TDAmeritradeAPI call.
  
# Example
```julia
moversToJSON(s)
some("[{\"change\":0.14539007092198572,\"description\":\"West Pharmaceutical Services, Inc. Common Stock\",\"direction\":\"up\",\"last\":319.77,\"symbol\":\"WST\",\"totalVolume\":2034989},
       {\"change\":0.05242518059855519,\"description\":\"Cisco Systems, Inc. - Common Stock\",\"direction\":\"up\",\"last\":50.99,\"symbol\":\"CSCO\",\"totalVolume\":48125324}
[...]
```
"""
function moversToJSON(m::Movers)::ErrorTypes.Option{String}
    some(JSON3.write(m))
end

################################################################################
##
##  Movers JSON to DataFrame format conversion functions
##
################################################################################
"""
```julia
parseMoversJSONToDataFrame(json_string::String)::ErrorTypes.Option{DataFrame}
```

Convert the JSON string returned by a TDAmeritradeAPI get\\_movers API to a DataFrame.

Nested JSON objects will be flattened into columns in the output DataFrame.

An ErrorTypes.jl Option object will be returned that can be evaluated with ErrorTypes.@?

# Example
```julia
parseMoversJSONToDataFrame(json)
some(10x6 DataFrame
 Row | change     description                        direction  last     symbol  totalVolume
     | Float64    String                             String     Float64  String  Int64
 -------------------------------------------------------------------------------------------
   1 | 0.14539    West Pharmaceutical Services, In   up          319.77  WST         2034989
   2 | 0.0524252  Cisco Systems, Inc. - Common Sto   up           50.99  CSCO       48125324
   3 | 0.0470325  Albemarle Corporation Common Sto   up          285.62  ALB         3497048
   4 | 0.0405268  Catalent, Inc. Common Stock        up           71.89  CTLT        2572417
[...]
```
"""
function parseMoversJSONToDataFrame(json_string::String)::ErrorTypes.Option{DataFrame}
    _moversJSONToDataFrame(json_string)
end

