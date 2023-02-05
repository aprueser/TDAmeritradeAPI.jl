using TDAmeritradeAPI
using Test
using Dates, ErrorTypes, JSON3

## Enter your TDAmeritrade API key here for local testing, remove before committing
apiKey = TDAmeritradeAPI.apiKeys("WJVM0PUSEA6DOJSBG3LNR14UIX5CVMAO", "", now(), "", now(), now() - Minute(30), "unauthorized");
badKey = TDAmeritradeAPI.apiKeys("WJVMPSADJB3NR14UIX5CVMAO", "", now(), "", now(), now() - Minute(30), "unauthorized");

function loadSampleJSON(type::String)::Result{String, String}

    filename::Union{Nothing, String} = nothing;

    @time if type == "priceHistory" 
        filename = "./sample/pricehistory.json"
    end

    isnothing(filename) ? nothing : read("./sample/pricehistory.json", String)
end

function parsePriceHistoryToStuct()
    @time cl = TDAmeritradeAPI._jsonToCandleList(loadSampleJSON("priceHistory"))
end

@testset "TDAmeritradeAPI.PriceHistory" begin
    @test expect(TDAmeritradeAPI._getPriceHistory("SPY", apiKey, numPeriods=1), "ERROR") != "ERROR"                                  skip = false
    @test expect(TDAmeritradeAPI.api_getPriceHistoryRaw("SPY", apiKey, numPeriods=1), "ERROR") != "ERROR"                            skip = false
    @test expect_error(TDAmeritradeAPI.api_getPriceHistoryRaw("SPY", badKey, numPeriods=1), "PASS") == "500::Internal Server Error"  skip = false

    @test expect(TDAmeritradeAPI.api_getPriceHistoryDF("SPY", apiKey, numPeriods=1), "ERROR") != "ERROR"                                  skip = false

    @test parsePriceHistoryToStuct() isa Result{TDAmeritradeAPI.CandleList}

end
