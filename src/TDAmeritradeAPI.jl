module TDAmeritradeAPI

    ## Function Exports
    export  ## Quotes
            api_getQuoteRaw,
            api_getQuoteDF,
            api_getQuotesRaw,
            api_getQuotesDF,
            ## Movers
            api_getMoversRaw,
            api_getMoversDF,
            ## Instruments
            api_getInstrumentRaw,
            api_getInstrumentDF,
            api_searchInstrumentsRaw,
            api_searchInstrumentsDF,
            ## MarketHours
            api_getMarketHoursRaw,
            api_getMarketHoursDF,
            ## PriceHistory
            api_getPriceHistoryRaw,
            api_getPriceHistoryDF,
            api_getPriceHistoryTA,
            api_getPriceHistoryTS,
            ## OptionChains
            api_getOptionChainRaw,
            api_getOptionChainDF,
            ## Supporting Objects
            apiKeys,
            listEndpoints,
            validMarkets;

    ## Dependent Packages
    using ArgCheck, HTTP,
          LazyArrays, LazyJSON, 
          StructTypes, StructArrays, 
          Dates, TimeZones,
          Tables, DataFrames, DataFramesMeta, 
          TimeSeries, Temporal

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

    include("optionschain.jl")
    include("pricehistory.jl")
    include("instruments.jl")
    include("markethours.jl")
    include("movers.jl")
    include("quotes.jl")

    ## Precompile directives
    precompile(api_getInstrumentRaw, (String, apiKeys));
    precompile(api_searchInstrumentsRaw, (String, String, apiKeys));
    precompile(api_getInstrumentDF, (String, apiKeys));
    precompile(api_searchInstrumentsDF, (String, String, apiKeys));

    precompile(api_getQuotesRaw, (Vector{String}, apiKeys))
    precompile(api_getQuotesRaw, (String, apiKeys));
    precompile(api_getQuoteRaw, (String, apiKeys));
    precompile(api_getQuotesDF, (Vector{String}, apiKeys))
    precompile(api_getQuotesDF, (String, apiKeys));
    precompile(api_getQuoteDF, (String, apiKeys));

end ## End TDAmeritradeAPI
