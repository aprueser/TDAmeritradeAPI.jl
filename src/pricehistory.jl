module PriceHistory

    using LazyJSON, StructTypes, Dates, DataFrames, TimeSeries, Temporal;

    struct Candle
        close::Float64
        datetime::Int64
        high::Float64
        low::Float64
        open::Float64
        volume::Int64
    end

    struct CandleList
        candles::Array{Candle}
        empty::Bool
        symbol::String
    end

    StructTypes.StructType(::Type{Candle})     = StructTypes.Struct()
    StructTypes.StructType(::Type{CandleList}) = StructTypes.Struct()

    ## Note: Dates are in UTC.
    ##astimezone(ZonedDateTime(dfInst.quoteTimeInLong[1], tz"UTC"), tz"America/New_York")
    function toDataFrame(ljson::LazyJSON.Object{Nothing, String})
        cl::CandleList = convert(CandleList, ljson)

        fields = Vector{String}(["Open", "High", "Low", "Close", "Volume"]);
        index  = map(x -> Dates.unix2datetime(x.datetime/1000), cl.candles)
        values = Array{Float64}(reduce(hcat, map(x -> [x.open, x.high, x.low, x.close, x.volume], cl.candles))');

        df = DataFrame(values, fields)
        DataFrames.insertcols!(df, 1, :Datetime => index, :Symbol => ljson["symbol"])

        return df
    end

    ## Note: Dates are un UTC.  
    function toTemporalTS(ljson::LazyJSON.Object{Nothing, String})
        cl::CandleList = convert(CandleList, ljson)

        fields = Vector{String}(["Open", "High", "Low", "Close", "Volume"]);
        index  =  map(x -> Dates.unix2datetime(x.datetime/1000), cl.candles)
        values = Array{Float64}(reduce(hcat, map(x -> [x.open, x.high, x.low, x.close, x.volume], cl.candles))');

        ohlcv = Temporal.TS(values, index, fields)

        return(ohlcv)
    end

    ## Note: Dates are un UTC.  
    function toTimeSeriesTA(ljson::LazyJSON.Object{Nothing, String})
        cl::CandleList = convert(CandleList, ljson)

        fields = Vector{String}(["Open", "High", "Low", "Close", "Volume"]);
        index  =  map(x -> Dates.unix2datetime(x.datetime/1000), cl.candles)
        values = Array{Float64}(reduce(hcat, map(x -> [x.open, x.high, x.low, x.close, x.volume], cl.candles))');

        ohlcv = TimeSeries.TimeArray(index, values, fields, String(ljson["symbol"]))

        return(ohlcv)
    end

end #PriceHistory