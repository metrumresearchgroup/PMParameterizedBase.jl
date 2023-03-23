function walkInitMacro(x, pnames, static_names, vnames, static_ignore, initBlock)
    x = MacroTools.striplines(x)
    if isexpr(x) && x.head == :macrocall && x.args[1] == Symbol("@init")
        push!(initBlock, x)
        isP = Vector{Bool}([false]) # Define a vector to see if recursion is in a parameter block or not
        out = MacroTools.postwalk(x -> walkParamsMacro(x, pnames, static_names), x)
        out = MacroTools.postwalk(x -> walkVariablesMacro(x, pnames, static_names, vnames), x)
        out = MacroTools.prewalk(x -> walkInit(x, pnames, static_names, vnames, static_ignore, isP), x)
    end
    return x
end

function walkInit(x, pnames, static_names, vnames, static_ignore, isP)
    if isexpr(x) && typeof(x) != LineNumberNode && ((@capture(x, a_ = b_) || @capture(x, a_ .= b_) || @capture(x, @__dot__ a_ = b_ ))) && !(@capture(x, @parameter _)) # Capture all non-parameter assignments
        if (x.head == :(=))
            nm = x.args[1]
            if nm ∉ pnames
                push!(static_names, nm)  # Push the name of the captured variable assignment to the static_names vector to save it
            elseif nm ∈ pnames && isP[end] == false
                if nm ∉ static_ignore
                    # TODO: Reconsider this warning. Is this really necessary?
                    @warn "Converting static definition of $nm to a @parameter"
                    push!(static_ignore, nm)
                end
            elseif nm ∈ vnames
                error("$nm already in use, cannot be used for variable name")
            elseif nm ∉ pnames && isP[end] == false
                error("Unrecognized error)")
            end
        end
        out = x
    else
        if @capture(x, @parameter _)
            push!(isP, true)
        end
        out = x
    end
    return out
end

