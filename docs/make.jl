push!(LOAD_PATH, "../src/")

using TDAmeritradeAPI
using Documenter

DocMeta.setdocmeta!(TDAmeritradeAPI, :DocTestSetup, :(using TDAmeritradeAPI); recursive=true)

makedocs(;
    sitename="TDAmeritradeAPI.jl",
    modules=[TDAmeritradeAPI],
    authors="Andrew Prueser <aprueser@gmail.com> and contributors",
    repo="https://github.com/aprueser/TDAmeritradeAPI.jl/blob/{commit}{path}#{line}",
    format=Documenter.HTML(;
        edit_link="main",
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://aprueser.github.io/TDAmeritradeAPI.jl",
        assets=String[],
    ),
    pages=[
        "Documentation" => "index.md",
        "Instruments"   => "instruments.md",
        "Market Hours"  => "marketHours.md",
        "Movers"        => "movers.md",
        "Option Chain"  => "optionChain.md",
        "Price History" => "priceHistory.md",
        "Quotes"        => "quotes.md",
    ],
)

deploydocs(;
    repo="github.com/aprueser/TDAmeritradeAPI.jl",
    devbranch="main",
    devurl="dev",
    versions=["stable" => "v^", "v#.#", "dev" => "dev"]
)
