function walkVariablesMacro(x, pnames, static_names, vnames)
    x = MacroTools.striplines(x)
    if isexpr(x) && x.head == :macrocall && x.args[1] == Symbol("@variable")
        isBlock = Vector{Bool}([false]) # DEfine a vector to see if recursion is in a block or not
        MacroTools.postwalk(x -> walkVariables(x, pnames, static_names, vnames, isBlock), x)
    end
    return x
end

function walkVariables(x, pnames, static_names, vnames, isBlock)
    if isexpr(x) && x.head == :block # Check if the parameter is being defined in a block. A block likely denotes an if/else statement or for loop.
        push!(isBlock, true)
    end
    if isexpr(x) && typeof(x) != LineNumberNode && ((@capture(x, a_ = b_) || @capture(x, a_ .= b_) || @capture(x, @__dot__ a_ = b_)))
        if (x.head == :(=))
            nm = x.args[1]
            if (nm ∉ pnames) && (nm  ∉ static_names) && (nm ∉ vnames)
                push!(vnames, nm)
            elseif isBlock[end] != true && nm ∈ vnames # If the last value of isBlock is true, this means that the parameter was defined in a block whcih likely denotes some sort of if/else or for loop and we can ignore this warning.
                # TODO: Maybe/probably should get rid of this, entirely? What's the point, we can just overwrite. 
                @warn "$nm is defined using '@variable' multiple times"
            elseif nm ∈ pnames
                error("$nm already used to define a @parameter, cannot be used for variable name")
            else
                error("Unrecognized error")
            end
        end
    end
    return x
end