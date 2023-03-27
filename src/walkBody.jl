function walkBodyMacro(x, derivatives, args)
    # if isexpr(x) && x.head == :macrocall && x.args[1] == Symbol("@ddt")
    if @capture(x, @ddt ddtDef_)
        dtracker = Vector{Symbol}() # Create a vector to track assigned variables and make sure that there are no "floating" derivatives. I.e derivatives without RHSs
        out = MacroTools.prewalk(x -> replaceDdt(x, derivatives, dtracker, args), x)
    else
        out = x
    end

    return out
end






function replaceDdt(x, derivatives, dtracker, args)
    dusym = args[1]
        if (@capture(x, a_ = b_) || @capture(x, a_ .= b_) || @capture(x, @__dot__ a_ = b_))
            nm = x.args[1]
            rhs = x.args[2]
            push!(derivatives, nm)
            push!(dtracker, nm)
            return :($dusym.$nm = $rhs)
        elseif typeof(x) == Symbol && x != Symbol("@ddt") && x != dusym
            if x != dtracker[end] # Check if the current symbol is equal to the previous symbol from variable assignment (i.e name = value) in the prewalk. If not, we have a "floating" or undefined derivative and should throw an error.
                error("Unrecognized derivative $x")
            end
        else
            return x
        end
end


function getRepeatedAssignments(x, dynamic_names)
    if isexpr(x) && typeof(x) != LineNumberNode && ((@capture(x, a_ = b_) || @capture(x, a_ .= b_) || @capture(x, @__dot__ a_ = b_)))
        if (x.head == :(=))
            nm = x.args[1]
            if nm ∉ dynamic_names
                push!(dynamic_names, nm)
            end
        end
    end
    return x
end

