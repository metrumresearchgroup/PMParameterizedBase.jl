function walkStatesMacro(x, state_names, state_block, stype)
    x = MacroTools.striplines(x)
    if isexpr(x) && x.head == :macrocall && x.args[1] == stype
        push!(state_block, x)
        blockprev = Vector{Bool}([false])
        out = MacroTools.postwalk(x -> walkState(x, state_names, state_block,blockprev, stype), x)
    else
        out = x
    end
    return out
end


function walkState(x, state_names, state_block, blockprev, stype)
    if isexpr(x) && x.head == :block
        push!(blockprev, true)
    end
    if isexpr(x) && typeof(x) != LineNumberNode && ((@capture(x, a_ = b_) || @capture(x, a_ .= b_) || @capture(x, @__dot__ a_ = b_ ))) 
        if (x.head == :(=))
            nm = x.args[1]
            if nm ∉ state_names
                push!(state_names, nm)
            elseif blockprev[end]!=true
                # TODO: Consider converting this to an error instead of a warning?
                if stype == Symbol("@mrparam")
                    @warn "Parameter $nm defined multiple time, last value will be used"
                elseif stype == Symbol("@constant")
                    @warn "Constant $nm defined multiple time, last value will be used"
                else
                    error("Unrecognized error")
                end
            end
        end
    else
    end
    return x
end

function buildState(state_block, stype, arguments, kwargs)
    # TODO: Figure out how to actually use the kwargs here. Maybe we should just throw an error if no default value is provided? Otherwise, pass extra kwargs from "solve" command?
    if stype == Symbol("@mrparam")
        fcn_name = gensym("Pfcn")
    elseif stype == Symbol("@constant")
        fcn_name = gensym("Cfcn")
    else
        error("Unrecognized error")
    end
    state_fcn = Expr(:function, :($fcn_name()), Expr(:block, state_block...))
    if stype == Symbol("@mrparam")
        state_fcn.args[1].args = vcat(state_fcn.args[1].args, kwargs...)
    elseif stype == Symbol("@constant")
        state_fcn.args[1].args = vcat(state_fcn.args[1].args, arguments...)
    else
        error("Unrecognized error")
    end
    return state_fcn
end



function parseState(modfn, arguments, kwargs, stype = Symbol("@mrparam"))
    state_names = []
    state_block = Vector{Expr}()
    MacroTools.postwalk(x -> walkStateMacro(x, state_names, state_block, stype), modfn)
    return_line = string("return ComponentArray{Float64}(")
    for nm in state_names
        return_line = string(return_line, "$nm = Float64($nm), ")
    end
    return_line = string(return_line, ")")
    return_line = Meta.parse(return_line)
    push!(state_block, return_line)
    state_fcn = buildState(state_block, stype, arguments, kwargs)
    return state_names, state_fcn
end