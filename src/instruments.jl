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
   
    if api_call == "array" 
        return some(DataFrame(values(i), copycols = false))
    end

    return some(DataFrame(values(i), copycols = false))
end


###############################################################################
##
##  Instruments - Function signiatures to return the JSON return as a String
##
###############################################################################
function api_getInstrumentAsJSON(cusip::String, apiKeys::TDAmeritradeAPI.apiKeys)::ErrorTypes.Result{String, String}
   _getInstrument(cusip, apiKeys);
end

function api_searchInstrumentsAsJSON(symbol::String, projection::String, apiKeys::TDAmeritradeAPI.apiKeys)::ErrorTypes.Result{String, String}
    _searchInstruments(symbol, projection, apiKeys);
end

###############################################################################
##
##  Instruments - Function signiatures to return DataFrames
##
###############################################################################
function api_getInstrumentAsDataFrame(cusip::String, apiKeys::TDAmeritradeAPI.apiKeys)::ErrorTypes.Option{DataFrame}

    httpRet = _getInstrument(cusip, apiKeys);

   _instrumentToDataFrame(ErrorTypes.@?(httpRet), "array")
end

function api_searchInstrumentsAsDataFrame(symbol::String, projection::String, apiKeys::TDAmeritradeAPI.apiKeys)::ErrorTypes.Option{DataFrame}

    httpRet = _searchInstruments(symbol, projection, apiKeys)

   _instrumentToDataFrame(ErrorTypes.@?(httpRet), "dict")
end

###############################################################################
##
##  Convert JSON to Struct
##
###############################################################################
function instrumentsToInstrumentDictStruct(json_string::String)::ErrorTypes.Option{InstrumentDict}
    some(JSON3.read(json_string, InstrumentDict))
end

function instrumentsToInstrumentArrayStruct(json_string::String)::ErrorTypes.Option{InstrumentArray}
    some(JSON3.read(json_string, InstrumentArray))
end

###############################################################################
##
##  Convert Struct to JSON
##
###############################################################################
function instrumentsToJSON(i::Union{InstrumentArray, InstrumentDict})::ErrorTypes.Option{String}
    some(JSON3.write(i))
end

################################################################################
##
##  Instruments to DataFrame format conversion functions
##
################################################################################
function parseInstrumentsJSONToDataFrame(json_string::String, api_call::String)::ErrorTypes.Option{DataFrame}
    @argcheck api_call in ["get", "search"]
    
    _instrumentToDataFrame(json_string, api_call == "get" ? "array" : "dict")
end
