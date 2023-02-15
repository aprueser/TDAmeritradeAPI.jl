push!(LOAD_PATH, "../src/")

using TDAmeritradeAPI
using Documenter

DocMeta.setdocmeta!(TDAmeritradeAPI, :DocTestSetup, :(using TDAmeritradeAPI); recursive=true)

makedocs(;
    sitename="TDAmeritradeAPI.jl",
    modules=[TDAmeritradeAPI],
    authors="Andrew Prueser <aprueser@gmail.com> and contributors",
    format=Documenter.HTML(;
        edit_link="main",
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://aprueser.github.io/TDAmeritradeAPI.jl",
        assets=String[],
    ),
    pages=[
        "Documentation" => "index.md",
        "Option Chain" => "optionChain.md",
    ],
)

deploydocs(;
    repo="github.com/aprueser/TDAmeritradeAPI.jl",
    devbranch="main",
    devurl="dev",
    versions=["stable" => "v^", "v#.#", "dev" => "dev"]
)
