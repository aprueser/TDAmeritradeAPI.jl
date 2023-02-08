using TDAmeritradeAPI
using Test
using Dates, ErrorTypes, JSON3

## Enter your TDAmeritrade API key here for local testing, remove before committing
apiKey = TDAmeritradeAPI.apiKeys("WJVM0PUSEA6DOJSBG3LNR14UIX5CVMAO", "", now(), "", now(), now() - Minute(30), "unauthorized");
badKey = TDAmeritradeAPI.apiKeys("WJVMPSADJB3NR14UIX5CVMAO", "", now(), "", now(), now() - Minute(30), "unauthorized");

function loadSampleJSON(type::String)::Result{String, String}

    filename::Union{Nothing, String} = nothing;

    if type == "priceHistory" 
        filename = "./sample/pricehistory.json"
    end

    isnothing(filename) ? Err(nothing) : Ok(read(filename, String))
end

function parsePriceHistoryToStuct()::Option{TDAmeritradeAPI.CandleList}
    TDAmeritradeAPI.priceHistoryToCandleListStruct(ErrorTypes.@?(loadSampleJSON("priceHistory")))
end

@testset verbose = true showtiming = true "TDAmeritradeAPI.PriceHistory" begin
    @test expect(TDAmeritradeAPI._getPriceHistory("SPY", apiKey, numPeriods=1), "ERROR") != "ERROR"                                     skip = false
    
    @test expect(TDAmeritradeAPI.api_getPriceHistoryAsJSON("SPY", apiKey, numPeriods=1), "ERROR") != "ERROR"                            skip = true
    @test expect_error(TDAmeritradeAPI.api_getPriceHistoryAsJSON("SPY", badKey, numPeriods=1), "PASS") == "500::Internal Server Error"  skip = true
    
    @test expect(TDAmeritradeAPI.api_getPriceHistoryAsDataFrame("SPY", apiKey, numPeriods=1), "ERROR") != "ERROR"                       skip = true

    @test ErrorTypes.@?(parsePriceHistoryToStuct()) isa TDAmeritradeAPI.CandleList

end
