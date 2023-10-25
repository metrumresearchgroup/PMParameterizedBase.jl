using PMParameterizedBase
using Documenter

DocMeta.setdocmeta!(PMParameterizedBase, :DocTestSetup, :(using PMParameterizedBase); recursive=true)

makedocs(;
    modules=[PMParameterizedBase],
    authors="Timothy Knab",
    repo="https://github.com/timknab/PMParameterizedBase.jl/blob/{commit}{path}#{line}",
    sitename="PMParameterizedBase.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://timknab.github.io/PMParameterizedBase.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/timknab/PMParameterizedBase.jl",
    devbranch="main",
)
