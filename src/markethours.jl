module MarketHours

    using LazyJSON, Dates, TimeZones, DataFrames, DataFramesMeta

    export validMarkets

    validMarkets = ["EQUITY", "OPTION", "FUTURE", "BOND", "FOREX"];

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

    function toDataFrame(ljson::LazyJSON.Object{Nothing, String})
        dateFmt     = Dates.DateFormat("yyyy-mm-dd");
        dateTimeFmt = Dates.DateFormat("yyyy-mm-ddTHH:MM:SSzzzz");

        vecMarket = Vector{Market}()
        vecHours  = Vector{SessionHours}()
        for k::String in keys(ljson)
            for (ky, vy) in ljson[k]
                push!(vecMarket, convert(MarketHours.Market, vy))
        
                if !isnothing(vy["sessionHours"])
                    if haskey(vy["sessionHours"], "preMarket")
                        push!(vecHours, MarketHours.SessionHours(ky, "preMarket", DateTime(ZonedDateTime(vy["sessionHours"]["preMarket"][1]["start"], dateTimeFmt)), 
                                                                                  DateTime(ZonedDateTime(vy["sessionHours"]["preMarket"][1]["end"], dateTimeFmt))))
                    end
                    
                    if haskey(vy["sessionHours"], "regularMarket")
                        push!(vecHours, MarketHours.SessionHours(ky, "regularMarket", DateTime(ZonedDateTime(vy["sessionHours"]["regularMarket"][1]["start"], dateTimeFmt)), 
                                                                                      DateTime(ZonedDateTime(vy["sessionHours"]["regularMarket"][1]["end"], dateTimeFmt))))
                    end
                    
                    if haskey(vy["sessionHours"], "postMarket")
                        push!(vecHours, MarketHours.SessionHours(ky, "postMarket", DateTime(ZonedDateTime(vy["sessionHours"]["postMarket"][1]["start"], dateTimeFmt)), 
                                                                                   DateTime(ZonedDateTime(vy["sessionHours"]["postMarket"][1]["end"], dateTimeFmt))))
                    end
        
                    if haskey(vy["sessionHours"], "outcryMarket")
                        push!(vecHours, MarketHours.SessionHours(ky, "outcryMarket", DateTime(ZonedDateTime(vy["sessionHours"]["outcryMarket"][1]["start"], dateTimeFmt)), 
                                                                                     DateTime(ZonedDateTime(vy["sessionHours"]["outcryMarket"][1]["end"], dateTimeFmt))))
                    end
                end
            end
        end
        
        df = leftjoin(DataFrame(vecMarket, copycols = false), DataFrame(vecHours, copycols = false), on = :product)

        @transform! df begin
            :date = Date.(:date, dateFmt)
        end

        return(df)
    end

end # End MarketHours