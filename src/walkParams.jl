

function walkParams(x, pnames, static_names, isBlock)
    if isexpr(x) && x.head == :block # Check if the parameter is being defined in a block. A block likely denotes an if/else statement or for loop.
        push!(isBlock, true)
    end
    if isexpr(x) && typeof(x) != LineNumberNode && ((@capture(x, a_ = b_) || @capture(x, a_ .= b_) || @capture(x, @__dot__ a_ = b_)))
        if (x.head == :(=))
            nm = x.args[1]
            if (nm ∉ pnames) && (nm  ∉ static_names)
                push!(pnames, nm)
            elseif isBlock[end] != true && nm ∈ pnames # If the last value of isPblock is true, this means that the parameter was defined in a block whcih likely denotes some sort of if/else or for loop and we can ignore this warning.
                @warn "$nm is defined using '@parameter' multiple times. Last value will be used."
            else
                error("Unrecognized error")
            end
            push!(isBlock, false)
        end
    end
    return x
end