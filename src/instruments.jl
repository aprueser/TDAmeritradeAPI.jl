module Instruments

    using LazyJSON, LazyArrays, StructTypes, Dates, DataFrames, DataFramesMeta;

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

    StructTypes.StructType(::Type{Bond})            = StructTypes.Struct()
    StructTypes.StructType(::Type{FundamentalData}) = StructTypes.Struct()
    StructTypes.StructType(::Type{Fundamental})     = StructTypes.Struct()
    StructTypes.StructType(::Type{Instrument})      = StructTypes.Struct()

    function toDataFrame(ljson::LazyJSON.Array{Nothing, String}, projection::String) 
            v = Vector{Instrument}(collect(values(ljson)))

            nt = (cusip=BroadcastArray((x -> x.cusip), v), 
                  symbol=BroadcastArray((x -> x.symbol), v),
                  description=BroadcastArray((x -> x.description), v),
                  exchange=BroadcastArray((x -> x.exchange), v),
                  assetType=BroadcastArray((x -> x.assetType), v));

            return DataFrame(nt, copycols=false)
    end

    function toDataFrame(ljson::LazyJSON.Object{Nothing, String}, projection::String)
        
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

end ## Instruments Module