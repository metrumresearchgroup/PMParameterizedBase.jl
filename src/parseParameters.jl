
function walkParamMacro(x, psym, pnames, pvals, pblock)
    x = MacroTools.striplines(x)
    if isexpr(x) && x.head == :macrocall
        push!(pblock,x)
        out = MacroTools.prewalk(x -> walkParam(x, psym, pnames, pvals), x)
    else
        out = x
    end
    return out
end
function walkParam(x, psym, pnames, pvals)
    if isexpr(x) && typeof(x) != LineNumberNode && ((@capture(x, a_ = b_) || @capture(x, a_ .= b_) || @capture(x, @__dot__ a_ = b_ ))) 
        if (x.head == :(=))
            pn = x.args[1]
            pv = x.args[2]
            push!(pnames, pn)
            push!(pvals, pv)
        else
        end
    else
    end
    return x
end
function parseParameters(modfn)
    psym = :params
    pnames = []
    pvals = []
    pblock = Vector{Expr}()
    MacroTools.postwalk(x -> walkParamMacro(x, psym, pnames, pvals, pblock), modfn)
    return_line = string("return ComponentArray(")
    for pn in pnames
        return_line = string(return_line, "$pn = Float64($pn), ")
    end
    return_line = string(return_line, ")")
    return_line = Meta.parse(return_line)
    push!(pblock, return_line)
    pfcn = Expr(:function, :(Pfcn()), Expr(:block, pblock...))
    return psym, pnames, pvals, pfcn
end