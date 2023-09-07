using MacroTools

function rewriteDMacro(ex, formula)
    dsplit = split(string(ex), "_")
    macrout = join(["@D", dsplit[2:end]..., string(formula)]," ")
end

function parseDMacro(MdlEx)
    MdlEx = MacroTools.postwalk(x -> @capture(x, @D__ formula_) ? rewriteDMacro(D[1], formula) : x, MdlEx)
end