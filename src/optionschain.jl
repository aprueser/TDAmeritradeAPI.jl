module OptionChains

    using HTTP, LazyJSON, StructTypes, Dates, DataFrames, DataFramesMeta;

    struct Underlying
        ask::Union{Float64, Nothing}
        askSize::Int32
        bid::Union{Float64, Nothing}
        bidSize::Int32
        change::Union{Float64, Nothing}
        close::Union{Float64, Nothing}
        delayed::Union{Bool, Nothing}
        description::String
        exchangeName::String
        fiftyTwoWeekHigh::Union{Float64, Nothing}
        fiftyTwoWeekLow::Union{Float64, Nothing}
        highPrice::Union{Float64, Nothing}
        last::Union{Float64, Nothing}
        lowPrice::Union{Float64, Nothing}
        mark::Union{Float64, Nothing}
        markChange::Union{Float64, Nothing}
        markPercentChange::Union{Float64, Nothing}
        openPrice::Union{Float64, Nothing}
        percentChange::Union{Float64, Nothing}
        quoteTime::Int64
        symbol::String
        totalVolume::Int64
        tradeTime::Int64
    end

    struct OptionDeliverables
        symbol::String
        assetType::String
        deliverableUnits::String
        currencyType::String
    end

    struct StrikePriceMap
        putCall::String
        symbol::String
        description::String
        exchangeName::String
        bid::Union{Float64, Nothing}
        ask::Union{Float64, Nothing}
        last::Union{Float64, Nothing}
        mark::Union{Float64, Nothing}
        bidSize::Int32
        askSize::Int32
        bidAskSize::String
        lastSize::Int32
        highPrice::Union{Float64, Nothing}
        lowPrice::Union{Float64, Nothing}
        openPrice::Union{Float64, Nothing}
        closePrice::Union{Float64, Nothing}
        totalVolume::Int64
        tradeDate::Union{Int32, Nothing}
        quoteTimeInLong::Int64
        tradeTimeInLong::Int64
        netChange::Union{Float64, Nothing}
        volatility::Union{Float64, Nothing}
        delta::Union{Float64, Nothing}
        gamma::Union{Float64, Nothing}
        theta::Union{Float64, Nothing}
        vega::Union{Float64, Nothing}
        rho::Union{Float64, Nothing}
        openInterest::Union{Float64, Nothing}
        timeValue::Union{Float64, Nothing}
        theoreticalOptionValue::Union{Float64, Nothing}
        theoreticalVolatility::Union{Float64, Nothing}
        optionDeliverablesList::Union{Array{OptionDeliverables}, Nothing}
        strikePrice::Union{Float64, Nothing}
        expirationDate::Int64
        daysToExpiration::Union{Float64, Nothing}
        expirationType::String
        lastTradingDay::Union{Float64, Nothing}
        multiplier::Union{Float64, Nothing}
        settlementType::String
        deliverableNote::String
        isIndexOption::Union{Bool, Nothing}
        percentChange::Union{Float64, Nothing}
        markChange::Union{Float64, Nothing}
        markPercentChange::Union{Float64, Nothing}
        intrinsicValue::Union{Float64, Nothing}
        inTheMoney::Union{Bool, Nothing}
        mini::Union{Bool, Nothing}
        nonStandard::Union{Bool, Nothing}
        pennyPilot::Union{Bool, Nothing}
    end 

    struct OptionChain
        symbol::String
        status::String
        underlying::Union{Underlying, Nothing}
        strategy::String
        interval::Union{Float64, Nothing}
        isDelayed::Union{Bool, Nothing}
        isIndex::Union{Bool, Nothing}
        interestRate::Union{Float64, Nothing}
        underlyingPrice::Union{Float64, Nothing}
        volatility::Union{Float64, Nothing}
        daysToExpiration::Union{Int32, Nothing}
        numberOfContracts::Union{Int32, Nothing}
        putExpDateMap::Dict{String, Dict{String, Vector{StrikePriceMap}}}
        callExpDateMap::Dict{String, Dict{String, Vector{StrikePriceMap}}}
    end

    StructTypes.StructType(::Type{OptionChain})        = StructTypes.Struct()
    StructTypes.StructType(::Type{StrikePriceMap})     = StructTypes.Struct()
    StructTypes.StructType(::Type{Underlying})         = StructTypes.Struct()
    StructTypes.StructType(::Type{OptionDeliverables}) = StructTypes.Struct()

    function toDataFrame(ljson::LazyJSON.Object{Nothing, String})
        op::OptionChain = convert(OptionChain, ljson)

        df::DataFrame = DataFrame()

        for expDate in keys(op.putExpDateMap)
            for data in values(op.putExpDateMap[expDate])
                append!(df, DataFrame(data))
            end
        end

        for expDate in keys(op.callExpDateMap)
            for data in values(op.callExpDateMap[expDate])
                append!(df, DataFrame(data))
            end
        end

        DataFrames.insertcols!(df, 1, :Status => op.status, :Underlying => HTTP.unescapeuri(op.symbol), :UnderlyingPrice => op.underlyingPrice)

        if ljson["status"] != "FAILED"
            @transform! df @byrow begin
                :quoteTimeInLong = Dates.unix2datetime(:quoteTimeInLong/1000)
                :tradeTimeInLong = Dates.unix2datetime(:tradeTimeInLong/1000)
                :expirationDate  = Dates.unix2datetime(:expirationDate/1000)
                :lastTradingDay  = Dates.unix2datetime(:lastTradingDay/1000)
            end
        end

        return(df)
    end

end ## OptionChain Module
