function walkParamMacro(x, psym, pnames, pblock)
    x = MacroTools.striplines(x)
    if isexpr(x) && x.head == :macrocall
        push!(pblock, x)
        blockprev = Vector{Bool}([false])
        out = MacroTools.postwalk(x -> walkParam(x, psym, pnames, pblock,blockprev), x)
    else
        out = x
    end
    return out
end
function walkParam(x, psym, pnames, pblock,blockprev)
    if isexpr(x) && x.head == :block
        push!(blockprev, true)
    end
    if isexpr(x) && typeof(x) != LineNumberNode && ((@capture(x, a_ = b_) || @capture(x, a_ .= b_) || @capture(x, @__dot__ a_ = b_ ))) 
        if (x.head == :(=))
            pn = x.args[1]
            if pn ∉ pnames
                push!(pnames, pn)
            elseif blockprev[end]!=true
                # TODO: Consider converting this to an error instead of a warning?
                @warn "Parameter $pn defined multiple time, last value will be used"
            end
        end
    else
    end
    return x
end
function parseParameters(modfn, kwargs)
    psym = :params
    pnames = []
    pblock = Vector{Expr}()
    MacroTools.postwalk(x -> walkParamMacro(x, psym, pnames, pblock), modfn)
    return_line = string("return ComponentArray{Float64}(")
    for pn in pnames
        return_line = string(return_line, "$pn = Float64($pn), ")
    end
    return_line = string(return_line, ")")
    return_line = Meta.parse(return_line)
    push!(pblock, return_line)
    # TODO: Figure out how to actually use the kwargs here. Maybe we should just throw an error if no default value is provided? Otherwise, pass extra kwargs from "solve" command?
    pfcn = Expr(:function, :(Pfcn()), Expr(:block, pblock...))
    pfcn.args[1].args = vcat(pfcn.args[1].args, kwargs...)
    return psym, pnames, pfcn
end