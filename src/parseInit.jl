include("walkInit.jl")
include("walkParams.jl")
include("walkVariables.jl")

function parseInit(modfn, arguments)
    walkDefs(modfn)
    pnames = Vector{Symbol}()
    static_names = Vector{Symbol}()
    vnames = Vector{Symbol}()
    static_ignore = Vector{Symbol}() # Use the static ignore so warnings only show once.
    initBlock = Vector{Expr}()
    MacroTools.postwalk(x -> walkInitMacro(x, pnames, static_names, vnames, static_ignore, initBlock), modfn)
    return pnames, static_names, vnames, initBlock
end
