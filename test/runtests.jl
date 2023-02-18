using TDAmeritradeAPI
using Test
using Dates, ErrorTypes, JSON3, DataFrames, TimeSeries

## Skip the API Call tests
skipAPITests = false

## Enter your TDAmeritrade API key here for local testing, remove before committing
apiKey = TDAmeritradeAPI.apiKeys(ENV["TDA_CUST_KEY"], "", now(), "", now(), now() - Minute(30), "unauthorized");
badKey = TDAmeritradeAPI.apiKeys(ENV["TDA_BAD_KEY"], "", now(), "", now(), now() - Minute(30), "unauthorized");

function loadSampleJSON(type::String)::Result{String, String}

    filename::Union{Nothing, String} = nothing;

    if type == "instrumentsEquity"
        filename = "./sample/instrument_equity.json"
    elseif type == "instrumentsBond"
        filename = "./sample/instrument_single_bond.json"
    elseif type == "instrumentsFundamentals"
        filename = "./sample/instrument_fundamental_equity.json"
    elseif type == "instrumentsSearch"
        filename = "./sample/instrument_search_multiple_results.json"
    elseif type == "marketHoursAll"
        filename = "./sample/markethours_multiple_all.json"
    elseif type == "marketHoursEquity"
        filename = "./sample/markethours_single_equity.json"
    elseif type == "marketHoursForex"
        filename = "./sample/markethours_single_forex.json"
    elseif type == "marketHoursOption"
        filename = "./sample/markethours_single_option.json"
    elseif type == "movers"
        filename = "./sample/movers.json"
    elseif type == "optionChainEquity"
        filename = "./sample/optionchain_equity.json"
    elseif type == "priceHistory"
        filename = "./sample/pricehistory.json"
    elseif type == "quotesForex"
        filename = "./sample/quotes_forex.json"
    elseif type == "quotesFuture"
        filename = "./sample/quotes_future.json"
    elseif type == "quotesIndex"
        filename = "./sample/quotes_index.json"
    elseif type == "quotesMultiEquity"
        filename = "./sample/quotes_multiple_equity.json"
    elseif type == "quotesMultiMix"
        filename = "./sample/quotes_multiple_mix.json"
    elseif type == "quotesMutualFund"
        filename = "./sample/quotes_mutualfund.json"
    elseif type == "quotesSingleEquity"
        filename = "./sample/quotes_single_equity.json"
    elseif type == "quotesSingleEquityOption"
        filename = "./sample/quotes_single_equity_option.json"
    elseif type == "quotesSingleETF"
        filename = "./sample/quotes_single_etf.json"
    elseif type == "quotesSymNotFound"
        filename = "./sample/quotes_sym_not_found.json"
    end

    isnothing(filename) ? Err(nothing) : Ok(read(filename, String))
end

@testset verbose = true "TDAmeritradeAPI.Instruments" begin
    @testset "HTTP Calls" begin
        @test expect(TDAmeritradeAPI._getInstrument("SPY", apiKey), "ERROR") != "ERROR"                             skip = skipAPITests
        @test expect(TDAmeritradeAPI._searchInstruments("NET", "fundamental", apiKey), "ERROR") != "ERROR"          skip = skipAPITests
        @test expect(TDAmeritradeAPI._searchInstruments("SPY", "symbol-search", apiKey), "ERROR") != "ERROR"        skip = skipAPITests
        @test expect(TDAmeritradeAPI._searchInstruments("SP.*", "symbol-regex", apiKey), "ERROR") != "ERROR"        skip = skipAPITests
        @test expect(TDAmeritradeAPI._searchInstruments("VIX", "desc-search", apiKey), "ERROR") != "ERROR"          skip = skipAPITests
        @test expect(TDAmeritradeAPI._searchInstruments(".*Standard.*", "desc-regex", apiKey), "ERROR") != "ERROR"  skip = skipAPITests

        @test expect(TDAmeritradeAPI.api_getInstrumentAsJSON("SPY", apiKey), "ERROR") != "ERROR"                             skip = skipAPITests
        @test expect(TDAmeritradeAPI.api_searchInstrumentsAsJSON("NET", "fundamental", apiKey), "ERROR") != "ERROR"          skip = skipAPITests
        @test expect(TDAmeritradeAPI.api_searchInstrumentsAsJSON("SPY", "symbol-search", apiKey), "ERROR") != "ERROR"        skip = skipAPITests
        @test expect(TDAmeritradeAPI.api_searchInstrumentsAsJSON("SP.*", "symbol-regex", apiKey), "ERROR") != "ERROR"        skip = skipAPITests
        @test expect(TDAmeritradeAPI.api_searchInstrumentsAsJSON("VIX", "desc-search", apiKey), "ERROR") != "ERROR"          skip = skipAPITests
        @test expect(TDAmeritradeAPI.api_searchInstrumentsAsJSON(".*Standard.*", "desc-regex", apiKey), "ERROR") != "ERROR"  skip = skipAPITests

        @test expect(TDAmeritradeAPI.api_getInstrumentAsDataFrame("SPY", apiKey), "ERROR") != "ERROR"                             skip = skipAPITests
        @test expect(TDAmeritradeAPI.api_searchInstrumentsAsDataFrame("NET", "fundamental", apiKey), "ERROR") != "ERROR"          skip = skipAPITests
        @test expect(TDAmeritradeAPI.api_searchInstrumentsAsDataFrame("SPY", "symbol-search", apiKey), "ERROR") != "ERROR"        skip = skipAPITests
        @test expect(TDAmeritradeAPI.api_searchInstrumentsAsDataFrame("SP.*", "symbol-regex", apiKey), "ERROR") != "ERROR"        skip = skipAPITests
        @test expect(TDAmeritradeAPI.api_searchInstrumentsAsDataFrame("VIX", "desc-search", apiKey), "ERROR") != "ERROR"          skip = skipAPITests
        @test expect(TDAmeritradeAPI.api_searchInstrumentsAsDataFrame(".*Standard.*", "desc-regex", apiKey), "ERROR") != "ERROR"  skip = skipAPITests
    end

    @testset "To Structs" begin
        @test ErrorTypes.@?(TDAmeritradeAPI.instrumentsToInstrumentArrayStruct(ErrorTypes.@?(loadSampleJSON("instrumentsEquity")))) isa TDAmeritradeAPI.InstrumentArray
        @test ErrorTypes.@?(TDAmeritradeAPI.instrumentsToInstrumentArrayStruct(ErrorTypes.@?(loadSampleJSON("instrumentsBond")))) isa TDAmeritradeAPI.InstrumentArray
        @test ErrorTypes.@?(TDAmeritradeAPI.instrumentsToInstrumentDictStruct(ErrorTypes.@?(loadSampleJSON("instrumentsFundamentals")))) isa TDAmeritradeAPI.InstrumentDict
        @test ErrorTypes.@?(TDAmeritradeAPI.instrumentsToInstrumentDictStruct(ErrorTypes.@?(loadSampleJSON("instrumentsSearch")))) isa TDAmeritradeAPI.InstrumentDict
    end

    @testset "To DataFrame" begin
        @test ErrorTypes.@?(TDAmeritradeAPI._instrumentJSONToDataFrame(ErrorTypes.@?(loadSampleJSON("instrumentsEquity")), "array")) isa DataFrame
        @test ErrorTypes.@?(TDAmeritradeAPI._instrumentJSONToDataFrame(ErrorTypes.@?(loadSampleJSON("instrumentsFundamentals")), "dict")) isa DataFrame

        @test ErrorTypes.@?(TDAmeritradeAPI.parseInstrumentsJSONToDataFrame(ErrorTypes.@?(loadSampleJSON("instrumentsEquity")), "get")) isa DataFrame
        @test ErrorTypes.@?(TDAmeritradeAPI.parseInstrumentsJSONToDataFrame(ErrorTypes.@?(loadSampleJSON("instrumentsFundamentals")), "search")) isa DataFrame
    end

    @testset "To JSON" begin
        @test ErrorTypes.@?(TDAmeritradeAPI.instrumentsToJSON(ErrorTypes.@?(TDAmeritradeAPI.instrumentsToInstrumentArrayStruct(ErrorTypes.@?(loadSampleJSON("instrumentsEquity")))))) isa String
        @test ErrorTypes.@?(TDAmeritradeAPI.instrumentsToJSON(ErrorTypes.@?(TDAmeritradeAPI.instrumentsToInstrumentDictStruct(ErrorTypes.@?(loadSampleJSON("instrumentsFundamentals")))))) isa String
    end
end

@testset verbose = true "TDAmeritradeAPI.MarketHours" begin
    @testset "HTTP Calls" begin
        @test expect(TDAmeritradeAPI._getMarketHours("EQUITY", apiKey), "ERROR") != "ERROR"                             skip = skipAPITests
        @test expect(TDAmeritradeAPI._getMarketHours(["EQUITY","OPTION"], apiKey), "ERROR") != "ERROR"                  skip = skipAPITests

        @test expect(TDAmeritradeAPI.api_getMarketHoursAsJSON("EQUITY", apiKey), "ERROR") != "ERROR"                    skip = skipAPITests
        @test expect(TDAmeritradeAPI.api_getMarketHoursAsJSON(["EQUITY","OPTION"], apiKey), "ERROR") != "ERROR"         skip = skipAPITests

        @test expect(TDAmeritradeAPI.api_getMarketHoursAsDataFrame("EQUITY", apiKey), "ERROR") != "ERROR"               skip = skipAPITests
        @test expect(TDAmeritradeAPI.api_getMarketHoursAsDataFrame(["EQUITY","OPTION"], apiKey), "ERROR") != "ERROR"    skip = skipAPITests
    end

    @testset "To Structs" begin
        @test ErrorTypes.@?(TDAmeritradeAPI.marketHoursToMarketTypesStruct(ErrorTypes.@?(loadSampleJSON("marketHoursAll")))) isa TDAmeritradeAPI.MarketTypes
        @test ErrorTypes.@?(TDAmeritradeAPI.marketHoursToMarketTypesStruct(ErrorTypes.@?(loadSampleJSON("marketHoursEquity")))) isa TDAmeritradeAPI.MarketTypes
        @test ErrorTypes.@?(TDAmeritradeAPI.marketHoursToMarketTypesStruct(ErrorTypes.@?(loadSampleJSON("marketHoursForex")))) isa TDAmeritradeAPI.MarketTypes
        @test ErrorTypes.@?(TDAmeritradeAPI.marketHoursToMarketTypesStruct(ErrorTypes.@?(loadSampleJSON("marketHoursOption")))) isa TDAmeritradeAPI.MarketTypes
    end

    @testset "To DataFrame" begin
        @test ErrorTypes.@?(TDAmeritradeAPI._marketHoursJSONToDataFrame(ErrorTypes.@?(loadSampleJSON("marketHoursAll")))) isa DataFrame
        @test ErrorTypes.@?(TDAmeritradeAPI._marketHoursJSONToDataFrame(ErrorTypes.@?(loadSampleJSON("marketHoursEquity")))) isa DataFrame
        @test ErrorTypes.@?(TDAmeritradeAPI._marketHoursJSONToDataFrame(ErrorTypes.@?(loadSampleJSON("marketHoursForex")))) isa DataFrame
        @test ErrorTypes.@?(TDAmeritradeAPI._marketHoursJSONToDataFrame(ErrorTypes.@?(loadSampleJSON("marketHoursOption")))) isa DataFrame

        @test ErrorTypes.@?(TDAmeritradeAPI.parseMarketHoursJSONToDataFrame(ErrorTypes.@?(loadSampleJSON("marketHoursAll")))) isa DataFrame
    end

    @testset "To JSON" begin
        @test ErrorTypes.@?(TDAmeritradeAPI.marketHoursToJSON(ErrorTypes.@?(TDAmeritradeAPI.marketHoursToMarketTypesStruct(ErrorTypes.@?(loadSampleJSON("marketHoursAll")))))) isa String
        @test ErrorTypes.@?(TDAmeritradeAPI.marketHoursToJSON(ErrorTypes.@?(TDAmeritradeAPI.marketHoursToMarketTypesStruct(ErrorTypes.@?(loadSampleJSON("marketHoursEquity")))))) isa String
        @test ErrorTypes.@?(TDAmeritradeAPI.marketHoursToJSON(ErrorTypes.@?(TDAmeritradeAPI.marketHoursToMarketTypesStruct(ErrorTypes.@?(loadSampleJSON("marketHoursForex")))))) isa String
        @test ErrorTypes.@?(TDAmeritradeAPI.marketHoursToJSON(ErrorTypes.@?(TDAmeritradeAPI.marketHoursToMarketTypesStruct(ErrorTypes.@?(loadSampleJSON("marketHoursOption")))))) isa String
    end
end

@testset verbose = true "TDAmeritradeAPI.Movers" begin
    @testset "HTTP Calls" begin
        @test expect(TDAmeritradeAPI._getMovers("\$DJI", "up", "percent", apiKey), "ERROR") != "ERROR"                             skip = skipAPITests
        
        @test expect(TDAmeritradeAPI.api_getMoversAsJSON("\$DJI", "up", "value", apiKey), "ERROR") != "ERROR"                      skip = skipAPITests
      
        @test expect(TDAmeritradeAPI.api_getMoversAsDataFrame("\$DJI", "down", "percent", apiKey), "ERROR") != "ERROR"             skip = skipAPITests
    end
    @testset "To Structs" begin
        @test ErrorTypes.@?(TDAmeritradeAPI.moversToMoversStruct(ErrorTypes.@?(loadSampleJSON("movers")))) isa TDAmeritradeAPI.Movers
    end

    @testset "To DataFrame" begin
        @test ErrorTypes.@?(TDAmeritradeAPI._moversJSONToDataFrame(ErrorTypes.@?(loadSampleJSON("movers")))) isa DataFrame

        @test ErrorTypes.@?(TDAmeritradeAPI.parseMoversJSONToDataFrame(ErrorTypes.@?(loadSampleJSON("movers")))) isa DataFrame
    end

    @testset "To JSON" begin
        @test ErrorTypes.@?(TDAmeritradeAPI.moversToJSON(ErrorTypes.@?(TDAmeritradeAPI.moversToMoversStruct(ErrorTypes.@?(loadSampleJSON("movers")))))) isa String
    end
end

@testset verbose = true "TDAmeritradeAPI.OptionChain" begin
    @testset "HTTP Calls" begin
        @test expect(TDAmeritradeAPI._getOptionChain("NET", apiKey), "ERROR") != "ERROR"                             skip = skipAPITests

        @test expect(TDAmeritradeAPI.api_getOptionChainAsJSON("NET", apiKey), "ERROR") != "ERROR"                    skip = skipAPITests

        @test expect(TDAmeritradeAPI.api_getOptionChainAsDataFrame("NET", apiKey), "ERROR") != "ERROR"               skip = skipAPITests
        @test expect(TDAmeritradeAPI.api_getOptionChainAsDataFrame("NET", apiKey, includeQuotes = true), "ERROR") != "ERROR"               skip = skipAPITests
    end

    @testset "To Structs" begin
        @test ErrorTypes.@?(TDAmeritradeAPI.optionChainToOptionChainStruct(ErrorTypes.@?(loadSampleJSON("optionChainEquity")))) isa TDAmeritradeAPI.OptionChain
    end

    @testset "To DataFrame" begin
        @test ErrorTypes.@?(TDAmeritradeAPI._optionChainJSONToDataFrame(ErrorTypes.@?(loadSampleJSON("optionChainEquity")))) isa DataFrame

        @test ErrorTypes.@?(TDAmeritradeAPI.parseOptionChainJSONToDataFrame(ErrorTypes.@?(loadSampleJSON("optionChainEquity")))) isa DataFrame
    end

    @testset "To JSON" begin
        @test ErrorTypes.@?(TDAmeritradeAPI.optionChainToJSON(ErrorTypes.@?(TDAmeritradeAPI.optionChainToOptionChainStruct(ErrorTypes.@?(loadSampleJSON("optionChainEquity")))))) isa String
    end
end

@testset verbose = true "TDAmeritradeAPI.PriceHistory" begin
    @testset "HTTP Calls" begin
        @test expect(TDAmeritradeAPI._getPriceHistory("SPY", apiKey, numPeriods=1), "ERROR") != "ERROR"                                     skip = skipAPITests
    
        @test expect(TDAmeritradeAPI.api_getPriceHistoryAsJSON("SPY", apiKey, numPeriods=1), "ERROR") != "ERROR"                            skip = skipAPITests
    
        @test expect(TDAmeritradeAPI.api_getPriceHistoryAsDataFrame("SPY", apiKey, numPeriods=1), "ERROR") != "ERROR"                       skip = skipAPITests
        @test expect(TDAmeritradeAPI.api_getPriceHistoryAsTimeArray("SPY", apiKey, numPeriods=1), "ERROR") != "ERROR"                       skip = skipAPITests

        @test expect_error(TDAmeritradeAPI.api_getPriceHistoryAsJSON("SPY", badKey, numPeriods=1), "PASS") == "500::Internal Server Error"  skip = skipAPITests
    end

    json_string = ErrorTypes.@?(loadSampleJSON("priceHistory"))
    @testset "To Structs" begin
        @test ErrorTypes.@?(TDAmeritradeAPI.priceHistoryToCandleListStruct(json_string)) isa TDAmeritradeAPI.CandleList
    end

    @testset "To DataFrame" begin
        @test ErrorTypes.@?(TDAmeritradeAPI._priceHistoryJSONToDataFrame(json_string)) isa DataFrame
        @test ErrorTypes.@?(TDAmeritradeAPI.parsePriceHistoryJSONToDataFrame(json_string)) isa DataFrame
    end

    @testset "To TimeArray" begin
        @test ErrorTypes.@?(TDAmeritradeAPI._priceHistoryJSONToTimeArray(json_string)) isa TimeSeries.TimeArray
        @test ErrorTypes.@?(TDAmeritradeAPI.parsePriceHistoryJSONToTimeArray(json_string)) isa TimeSeries.TimeArray
    end

    @testset "To JSON" begin
        @test ErrorTypes.@?(TDAmeritradeAPI.priceHistoryToJSON(ErrorTypes.@?(TDAmeritradeAPI.priceHistoryToCandleListStruct(json_string)))) isa String
    end
end

@testset verbose = true "TDAmeritradeAPI.Quotes" begin
    @testset "HTTP Calls" begin
        @test expect(TDAmeritradeAPI._getQuote("SPY", apiKey), "ERROR") != "ERROR"                                     skip = skipAPITests
        @test expect(TDAmeritradeAPI._getQuotes("SPY,QQQ", apiKey), "ERROR") != "ERROR"                                skip = skipAPITests

        @test expect(TDAmeritradeAPI.api_getQuoteAsJSON("SPY", apiKey), "ERROR") != "ERROR"                            skip = skipAPITests
        @test expect(TDAmeritradeAPI.api_getQuotesAsJSON(["SPY","QQQ"], apiKey), "ERROR") != "ERROR"                   skip = skipAPITests
        @test expect(TDAmeritradeAPI.api_getQuotesAsJSON("SPY,QQQ", apiKey), "ERROR") != "ERROR"                       skip = skipAPITests

        @test expect(TDAmeritradeAPI.api_getQuoteAsDataFrame("SPY", apiKey), "ERROR") != "ERROR"                       skip = skipAPITests
        @test expect(TDAmeritradeAPI.api_getQuotesAsDataFrame(["SPY","QQQ"], apiKey), "ERROR") != "ERROR"              skip = skipAPITests
        @test expect(TDAmeritradeAPI.api_getQuotesAsDataFrame("SPY,QQQ", apiKey), "ERROR") != "ERROR"                  skip = skipAPITests
    end

    @testset "To Structs" begin
        @test ErrorTypes.@?(TDAmeritradeAPI.quotesToQuoteStruct(ErrorTypes.@?(loadSampleJSON("quotesForex")))) isa TDAmeritradeAPI.QuoteArray
        @test ErrorTypes.@?(TDAmeritradeAPI.quotesToQuoteStruct(ErrorTypes.@?(loadSampleJSON("quotesFuture")))) isa TDAmeritradeAPI.QuoteArray
        @test ErrorTypes.@?(TDAmeritradeAPI.quotesToQuoteStruct(ErrorTypes.@?(loadSampleJSON("quotesIndex")))) isa TDAmeritradeAPI.QuoteArray
        @test ErrorTypes.@?(TDAmeritradeAPI.quotesToQuoteStruct(ErrorTypes.@?(loadSampleJSON("quotesMultiEquity")))) isa TDAmeritradeAPI.QuoteArray
        @test ErrorTypes.@?(TDAmeritradeAPI.quotesToQuoteStruct(ErrorTypes.@?(loadSampleJSON("quotesMultiMix")))) isa TDAmeritradeAPI.QuoteArray
        @test ErrorTypes.@?(TDAmeritradeAPI.quotesToQuoteStruct(ErrorTypes.@?(loadSampleJSON("quotesMutualFund")))) isa TDAmeritradeAPI.QuoteArray
        @test ErrorTypes.@?(TDAmeritradeAPI.quotesToQuoteStruct(ErrorTypes.@?(loadSampleJSON("quotesSingleEquity")))) isa TDAmeritradeAPI.QuoteArray
        @test ErrorTypes.@?(TDAmeritradeAPI.quotesToQuoteStruct(ErrorTypes.@?(loadSampleJSON("quotesSingleEquityOption")))) isa TDAmeritradeAPI.QuoteArray
        @test ErrorTypes.@?(TDAmeritradeAPI.quotesToQuoteStruct(ErrorTypes.@?(loadSampleJSON("quotesSingleETF")))) isa TDAmeritradeAPI.QuoteArray
        @test ErrorTypes.@?(TDAmeritradeAPI.quotesToQuoteStruct(ErrorTypes.@?(loadSampleJSON("quotesSymNotFound")))) isa TDAmeritradeAPI.QuoteArray
    end

    @testset "To DataFrame" begin
        @test ErrorTypes.@?(TDAmeritradeAPI._quotesJSONToDataFrame(ErrorTypes.@?(loadSampleJSON("quotesForex")))) isa DataFrame
        @test ErrorTypes.@?(TDAmeritradeAPI._quotesJSONToDataFrame(ErrorTypes.@?(loadSampleJSON("quotesFuture")))) isa DataFrame
        @test ErrorTypes.@?(TDAmeritradeAPI._quotesJSONToDataFrame(ErrorTypes.@?(loadSampleJSON("quotesIndex")))) isa DataFrame
        @test ErrorTypes.@?(TDAmeritradeAPI._quotesJSONToDataFrame(ErrorTypes.@?(loadSampleJSON("quotesMultiEquity")))) isa DataFrame
        @test ErrorTypes.@?(TDAmeritradeAPI._quotesJSONToDataFrame(ErrorTypes.@?(loadSampleJSON("quotesMultiMix")))) isa DataFrame
        @test ErrorTypes.@?(TDAmeritradeAPI._quotesJSONToDataFrame(ErrorTypes.@?(loadSampleJSON("quotesMutualFund")))) isa DataFrame
        @test ErrorTypes.@?(TDAmeritradeAPI._quotesJSONToDataFrame(ErrorTypes.@?(loadSampleJSON("quotesSingleEquity")))) isa DataFrame
        @test ErrorTypes.@?(TDAmeritradeAPI._quotesJSONToDataFrame(ErrorTypes.@?(loadSampleJSON("quotesSingleEquityOption")))) isa DataFrame
        @test ErrorTypes.@?(TDAmeritradeAPI._quotesJSONToDataFrame(ErrorTypes.@?(loadSampleJSON("quotesSingleETF")))) isa DataFrame
        @test ErrorTypes.@?(TDAmeritradeAPI._quotesJSONToDataFrame(ErrorTypes.@?(loadSampleJSON("quotesSymNotFound")))) isa DataFrame

        @test ErrorTypes.@?(TDAmeritradeAPI.parseQuotesJSONToDataFrame(ErrorTypes.@?(loadSampleJSON("quotesMultiMix")))) isa DataFrame
    end

    @testset "To JSON" begin
        @test ErrorTypes.@?(TDAmeritradeAPI.quotesToJSON(ErrorTypes.@?(TDAmeritradeAPI.quotesToQuoteStruct(ErrorTypes.@?(loadSampleJSON("quotesForex")))))) isa String
        @test ErrorTypes.@?(TDAmeritradeAPI.quotesToJSON(ErrorTypes.@?(TDAmeritradeAPI.quotesToQuoteStruct(ErrorTypes.@?(loadSampleJSON("quotesFuture")))))) isa String
        @test ErrorTypes.@?(TDAmeritradeAPI.quotesToJSON(ErrorTypes.@?(TDAmeritradeAPI.quotesToQuoteStruct(ErrorTypes.@?(loadSampleJSON("quotesIndex")))))) isa String
        @test ErrorTypes.@?(TDAmeritradeAPI.quotesToJSON(ErrorTypes.@?(TDAmeritradeAPI.quotesToQuoteStruct(ErrorTypes.@?(loadSampleJSON("quotesMultiEquity")))))) isa String
        @test ErrorTypes.@?(TDAmeritradeAPI.quotesToJSON(ErrorTypes.@?(TDAmeritradeAPI.quotesToQuoteStruct(ErrorTypes.@?(loadSampleJSON("quotesMultiMix")))))) isa String
        @test ErrorTypes.@?(TDAmeritradeAPI.quotesToJSON(ErrorTypes.@?(TDAmeritradeAPI.quotesToQuoteStruct(ErrorTypes.@?(loadSampleJSON("quotesMutualFund")))))) isa String
        @test ErrorTypes.@?(TDAmeritradeAPI.quotesToJSON(ErrorTypes.@?(TDAmeritradeAPI.quotesToQuoteStruct(ErrorTypes.@?(loadSampleJSON("quotesSingleEquity")))))) isa String
        @test ErrorTypes.@?(TDAmeritradeAPI.quotesToJSON(ErrorTypes.@?(TDAmeritradeAPI.quotesToQuoteStruct(ErrorTypes.@?(loadSampleJSON("quotesSingleEquityOption")))))) isa String
        @test ErrorTypes.@?(TDAmeritradeAPI.quotesToJSON(ErrorTypes.@?(TDAmeritradeAPI.quotesToQuoteStruct(ErrorTypes.@?(loadSampleJSON("quotesSingleETF")))))) isa String
        @test ErrorTypes.@?(TDAmeritradeAPI.quotesToJSON(ErrorTypes.@?(TDAmeritradeAPI.quotesToQuoteStruct(ErrorTypes.@?(loadSampleJSON("quotesSymNotFound")))))) isa String
    end
end

@testset verbose = true "TDAmeritradeAPI.Endpoints" begin
        @test TDAmeritradeAPI.listEndpoints()["get_quote"]["uri"] == "marketdata/{symbol}/quotes"
        @test badKey.custKey == "BADKEY123ABCZYX"
end
