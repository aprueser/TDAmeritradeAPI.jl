using TDAmeritradeAPI
using Test
using Dates, ErrorTypes, JSON3, DataFrames, TimeSeries

## Enter your TDAmeritrade API key here for local testing, remove before committing
apiKey = TDAmeritradeAPI.apiKeys("WJVM0PUSEA6DOJSBG3LNR14UIX5CVMAO", "", now(), "", now(), now() - Minute(30), "unauthorized");
badKey = TDAmeritradeAPI.apiKeys("WJVMPSADJB3NR14UIX5CVMAO", "", now(), "", now(), now() - Minute(30), "unauthorized");

function loadSampleJSON(type::String)::Result{String, String}

    filename::Union{Nothing, String} = nothing;

    if type == "priceHistory" 
        filename = "./sample/pricehistory.json"
    elseif type == "instrumentsEquity"
        filename = "./sample/instrument_equity.json"
    elseif type == "instrumentsBond"
        filename = "./sample/instrument_single_bond.json"
    elseif type == "instrumentsFundamentals"
        filename = "./sample/instrument_fundamental_equity.json"
    elseif type == "instrumentsSearch"
        filename = "./sample/instrument_search_multiple_results.json"
    end

    isnothing(filename) ? Err(nothing) : Ok(read(filename, String))
end

@testset verbose = true "TDAmeritradeAPI.PriceHistory" begin
    @testset "HTTP Calls" begin
        @test expect(TDAmeritradeAPI._getPriceHistory("SPY", apiKey, numPeriods=1), "ERROR") != "ERROR"                                     skip = false
    
        @test expect(TDAmeritradeAPI.api_getPriceHistoryAsJSON("SPY", apiKey, numPeriods=1), "ERROR") != "ERROR"                            skip = false
        @test expect_error(TDAmeritradeAPI.api_getPriceHistoryAsJSON("SPY", badKey, numPeriods=1), "PASS") == "500::Internal Server Error"  skip = false
    
        @test expect(TDAmeritradeAPI.api_getPriceHistoryAsDataFrame("SPY", apiKey, numPeriods=1), "ERROR") != "ERROR"                       skip = false
    end

    @testset "To Structs" begin
        @test ErrorTypes.@?(TDAmeritradeAPI.priceHistoryToCandleListStruct(ErrorTypes.@?(loadSampleJSON("priceHistory")))) isa TDAmeritradeAPI.CandleList
    end

    @testset "To DataFrame" begin
        @test ErrorTypes.@?(TDAmeritradeAPI._priceHistoryJSONToDataFrame(ErrorTypes.@?(loadSampleJSON("priceHistory")))) isa DataFrame
        @test ErrorTypes.@?(TDAmeritradeAPI.parsePriceHistoryJSONToDataFrame(ErrorTypes.@?(loadSampleJSON("priceHistory")))) isa DataFrame
    end

    @testset "To TimeArray" begin
        @test ErrorTypes.@?(TDAmeritradeAPI._priceHistoryJSONToTimeArray(ErrorTypes.@?(loadSampleJSON("priceHistory")))) isa TimeSeries.TimeArray
        @test ErrorTypes.@?(TDAmeritradeAPI.parsePriceHistoryJSONToTimeArray(ErrorTypes.@?(loadSampleJSON("priceHistory")))) isa TimeSeries.TimeArray
    end

    @testset "To JSON" begin
        @test ErrorTypes.@?(TDAmeritradeAPI.priceHistoryToJSON(ErrorTypes.@?(TDAmeritradeAPI.priceHistoryToCandleListStruct(ErrorTypes.@?(loadSampleJSON("priceHistory")))))) isa String
    end
end

@testset verbose = true "TDAmeritradeAPI.Instruments" begin
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
