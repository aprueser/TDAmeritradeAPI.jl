################################################################################
##
## Define Julia structs to hold the return of the API call
##
################################################################################
struct Bond
    bondPrice::Union{Float64, Nothing}
    cusip::Union{String, Nothing}
    symbol::String
    description::String
    exchange::String
    assetType::String
end

struct FundamentalData
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

struct Fundamental
    fundamental::Dict{String, FundamentalData}
    cusip::Union{String, Nothing}
    symbol::String
    description::String
    exchange::String
    assetType::String
end   

struct Instrument
    cusip::Union{String, Nothing}
    symbol::String
    description::String
    exchange::String
    assetType::String
end

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
function _getInstrument(cusip::String, apiKeys::TDAmeritradeAPI.apiKeys)
    @argcheck !ismissing(cusip)
    @argcheck !isnothing(cusip)
    @argcheck length(cusip) > 0

    queryParams = ["{cusip}" => cusip];

    bodyParams = Dict{String, Union{Number, String, Bool}}("apikey" => apiKeys.custKey);

    res = doHTTPCall("get_instrument", queryParams = queryParams, bodyParams = bodyParams);

    if haskey(res, :code) && res[:code] != 200
        res[:body] = haskey(instrumentsHTTPErrorMsg, res[:code]) ? instrumentsHTTPErrorMsg[res[:code]] * ". Symbol/cusip: " * cusip : "Invalid API Call for symbol/cusip " * cusip;
    end

    return(res)
end

function _searchInstruments(symbol::String, projection::String, apiKeys::TDAmeritradeAPI.apiKeys)
    @argcheck !ismissing(symbol)
    @argcheck !isnothing(symbol)
    @argcheck length(symbol) > 0
    @argcheck projection in ["fundamental", "symbol-search", "symbol-regex", "desc-search", "desc-regex"]

    bodyParams = Dict{String, Union{Number, String, Bool}}("symbol"     => symbol,
                                                          "projection" => projection,
                                                          "apikey"     => apiKeys.custKey);

    res = doHTTPCall("search_instruments", bodyParams = bodyParams);

    if haskey(res, :code) && res[:code] != 200
        res[:body] = haskey(instrumentsHTTPErrorMsg, res[:code]) ? instrumentsHTTPErrorMsg[res[:code]] * ". Symbol/regexp: " * symbol : "Invalid API Call for symbol/regexp " * symbol;
    end

    return(res)
end

###############################################################################
##
##  Instruments - Function signiatures to return the JSON return as a String
##
###############################################################################
function api_getInstrumentRaw(cusip::String, apiKeys::TDAmeritradeAPI.apiKeys)
    httpRet = _getInstrument(cusip, apiKeys);

    return(httpRet)
end

function api_searchInstrumentsRaw(symbol::String, projection::String, apiKeys::TDAmeritradeAPI.apiKeys)
    httpRet = _searchInstruments(symbol, projection, apiKeys);

    return(httpRet)
end

###############################################################################
##
##  Instruments - Function signiatures to return DataFrames
##
###############################################################################
function api_getInstrumentDF(cusip::String, apiKeys::TDAmeritradeAPI.apiKeys)::DataFrame

    httpRet = _getInstrument(cusip, apiKeys);

    if haskey(httpRet, :code) && httpRet[:code] == 200
        ljson = LazyJSON.value(httpRet[:body])

        if length(ljson) > 0 
            df = instrumentsToDataFrame(ljson, "symbol-search")
        else
            df = DataFrame([:httpCode => httpRet[:code], :httpMessage => httpRet[:message], :results => "No Instrument data found for symbol/cusip: " * cusip])
        end
    else
        df = DataFrame([:httpCode => httpRet[:code], :httpMessage => httpRet[:message], :results => httpRet[:body]])
    end
    
    return(df);
end

function api_searchInstrumentsDF(symbol::String, projection::String, apiKeys::TDAmeritradeAPI.apiKeys)::DataFrame

    httpRet = _searchInstruments(symbol, projection, apiKeys)

    if haskey(httpRet, :code) && httpRet[:code] == 200
        ljson = LazyJSON.value(httpRet[:body])

        if length(ljson) > 0 
            df = instrumentsToDataFrame(ljson, projection)
        else
            df = DataFrame([:httpCode => httpRet[:code], :httpMessage => httpRet[:message], :results => "No Instrument data found for symbol/regexp: " * symbol])
        end
    else
        df = DataFrame([:httpCode => httpRet[:code], :httpMessage => httpRet[:message], :results => httpRet[:body]])
    end
    
    return(df);
end


################################################################################
##
##  Instruments to DataFrame format conversion functions
##
################################################################################
function instrumentsToDataFrame(ljson::LazyJSON.Array{Nothing, String}, projection::String)::DataFrame
    v = Vector{Instrument}(collect(values(ljson)))

    nt = (cusip=BroadcastArray((x -> x.cusip), v), 
            symbol=BroadcastArray((x -> x.symbol), v),
            description=BroadcastArray((x -> x.description), v),
            exchange=BroadcastArray((x -> x.exchange), v),
            assetType=BroadcastArray((x -> x.assetType), v));

    return DataFrame(nt, copycols=false)
end

function instrumentsToDataFrame(ljson::LazyJSON.Object{Nothing, String}, projection::String)::DataFrame
    
    at = first(values(ljson))["assetType"]

    ## Handle the single returns first
    if projection == "fundamental"
    
        fv = first(values(ljson))
        
        vec = Vector{FundamentalData}()
        push!(vec, convert(FundamentalData, fv["fundamental"]))
        
        df = DataFrame(vec, copycols=false)

        DataFrames.insertcols!(df, 1, :cusip => fv["cusip"], :description => fv["description"], 
                                      :exchange => fv["exchange"], :assetType => fv["assetType"])

        @transform! df @byrow begin 
                    :dividendDate    = DateTime(ismissing(:dividendDate) || :dividendDate == " " ? "1900-01-01 00:00:00.000" : :dividendDate, dateformat"yyyy-mm-dd HH:MM:SS.sss") 
                    :dividendPayDate = DateTime(ismissing(:dividendPayDate) || :dividendPayDate == " " ? "1900-01-01 00:00:00.000" : :dividendPayDate, dateformat"yyyy-mm-dd HH:MM:SS.sss") 
        end
    
        return(df)

    elseif projection == "symbol-search" && at == "BOND"

        v = Vector{Bond}(collect(values(ljson)))

        nt = (bondPrice=BroadcastArray((x -> x.bondPrice), v), 
                cusip=BroadcastArray((x -> x.cusip), v), 
                symbol=BroadcastArray((x -> x.symbol), v),
                description=BroadcastArray((x -> x.description), v),
                exchange=BroadcastArray((x -> x.exchange), v),
                assetType=BroadcastArray((x -> x.assetType), v));

        return DataFrame(nt, copycols=true)

    elseif projection == "symbol-search" && at != "BOND"   

        v = Vector{Instrument}(collect(values(ljson)))

        nt = (cusip=BroadcastArray((x -> x.cusip), v), 
                symbol=BroadcastArray((x -> x.symbol), v),
                description=BroadcastArray((x -> x.description), v),
                exchange=BroadcastArray((x -> x.exchange), v),
                assetType=BroadcastArray((x -> x.assetType), v));

        return DataFrame(nt, copycols=true)
    
    # Now handle the potential multiple returns of one of the regex searches
    elseif projection == "symbol-regex" || projection == "desc-search" || projection == "desc-regex"

        v = Vector{Instrument}(collect(values(ljson)))

        nt = (cusip=BroadcastArray((x -> x.cusip), v), 
                symbol=BroadcastArray((x -> x.symbol), v),
                description=BroadcastArray((x -> x.description), v),
                exchange=BroadcastArray((x -> x.exchange), v),
                assetType=BroadcastArray((x -> x.assetType), v));

        return DataFrame(nt, copycols=true)

    end
end