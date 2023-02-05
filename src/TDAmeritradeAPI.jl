module TDAmeritradeAPI

    ## Dependent Packages
    using ArgCheck, 
          Dates,
          DataFrames,
          DataFramesMeta,
          ErrorTypes, 
          HTTP,
          JSON3,
          MiniLoggers, 
          Parameters,
          StructTypes,
          TimeSeries, 
          TimeZones

    mutable struct apiKeys
        custKey::String
        accessToken::String
        accessTokenExp::DateTime
        refreshToken::String
        refreshTokenExp::DateTime
        lastAPICallTime::DateTime
        mode::String
    end

    ## Internal Module Imports
    include("httpCalls.jl")
    include("utils.jl")

    include("optionschain.jl")
    include("pricehistory.jl")
    include("instruments.jl")
    include("markethours.jl")
    include("movers.jl")
    include("quotes.jl")

    ## Function Exports
    export  ## Quotes
            api_getQuoteAsJSON,
            api_getQuotesAsJSON,
            api_getQuotesAsJSON,
            api_getQuoteAsDataFrame,
            api_getQuotesAsDataFrame,
            api_getQuotesAsDataFrame,
            parseQuotesJSONToDataFrame,
            quotesToQuoteStruct,
            quotesToJSON,
            ## Movers
            api_getMoversAsJSON,
            api_getMoversAsDataFrame,
            parseMoversJSONToDataFrame,
            moversToMoversStruct,
            moversToJSON,
            ## Instruments
            api_getInstrumentAsJSON,
            api_getInstrumentAsDataFrame,
            api_searchInstrumentsAsJSON,
            api_searchInstrumentsAsDataFrame,
            parseInstrumentsJSONToDataFrame,
            instrumentsToInstrumentDictStruct,
            instrumentsToInstrumentArrayStruct,
            instrumentsToJSON,
            ## MarketHours
            api_getMarketHoursAsJSON,
            api_getMarketHoursAsDataFrame,
            parseMarketHoursJSONToDataFrame,
            marketHoursToMarketTypesStruct,
            marketHoursToJSON,
            ## PriceHistory
            api_getPriceHistoryAsJSON,
            api_getPriceHistoryAsDataFrame,
            api_getPriceHistoryAsTimeArray,
            parsePriceHistoryJSONToDataFrame,
            parsePriceHistoryJSONToTimeArray,
            priceHistoryToCandleListStruct,
            priceHistoryToJSON,
            ## OptionChains
            api_getOptionChainAsJSON,
            api_getOptionChainAsDataFrame,
            parseOptionChainJSONToDataFrame,
            optionChainToOptionChainStruct,
            optionChainToJSON,
            ## Supporting Objects
            apiKeys,
            listEndpoints,
            validMarkets;

    ## Precompile directives

end ## End TDAmeritradeAPI
