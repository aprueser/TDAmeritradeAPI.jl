using TDAmeritradeAPI
using Documenter

DocMeta.setdocmeta!(TDAmeritradeAPI, :DocTestSetup, :(using TDAmeritradeAPI); recursive=true)

makedocs(;
    modules=[TDAmeritradeAPI],
    authors="Andrew Prueser <aprueser@gmail.com> and contributors",
    repo="https://github.com/aprueser/TDAmeritradeAPI.jl/blob/{commit}{path}#{line}",
    sitename="TDAmeritradeAPI.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://aprueser.github.io/TDAmeritradeAPI.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/aprueser/TDAmeritradeAPI.jl",
    devbranch="main",
    devurl="dev",
    versions=["stable" => "v^", "v#.#", "dev" => "dev"]
)
