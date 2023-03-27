function parseInit(modfn, arguments)
    walkAndCheckDefs(modfn) # Make sure there are no parameter or variable definitions outside of an @init block
    pnames = Vector{Symbol}() # Create an empty vector for storing parameter names
    static_names = Vector{Symbol}() # Create an empty vector for storing the names of static variables
    vnames = Vector{Symbol}() # Create an empty vector to store the names of state variables
    static_ignore = Vector{Symbol}() # Use the static ignore so warnings only show once.
    initBlock = Vector{Expr}() # Create a vector to hold the expressions contained within an @init block
    MacroTools.postwalk(x -> walkInitMacro(x, pnames, static_names, vnames, static_ignore, initBlock), modfn) # Populate these vectors by walking through the expression tree
    return pnames, static_names, vnames, Expr(:block, initBlock...) # Return all variables
end


function rmLHSKwargs(x, kwsyms) # Create a function to remove lines that reassign the value of kwargs. If they are reassigned we can safely ignore the input value
    if isexpr(x) && typeof(x) != LineNumberNode && ((@capture(x, a_ = b_) || @capture(x, a_ .= b_) || @capture(x, @__dot__ a_ = b_)))
        if x.head == :(=) && x.args[1] ∈ kwsyms
            return nothing
        else
            return x
        end
    else
        return x
    end
end

function walkKwArgs(x, kwsyms, usedKwargs) # Check if a kwarg value is used anywhere in the code.
    if typeof(x) == Symbol && x ∈ kwsyms
        push!(usedKwargs, x) # If kwarg value is used, push the symbol to the usedKwargs vector
    end
    x
end



function kwargsUsedInInit(initBlock, kwargs_in)
    kwsyms = Vector{Symbol}() # Create a vector to hold all of the kwarg symbols
    usedKwargs = Vector{Symbol}() # Create a vector to hold kwargs that are used in the init function

    for kwargs in kwargs_in # Grab the kwarg symbols
        MacroTools.postwalk(x -> typeof(x) == Symbol ? (push!(kwsyms, x);x) : x, kwargs)
    end
    # Remove reassignemt of kwarg values within the initFcn. We can ignore those when we go to parse all variables in the funcotin
    rmkwrhs = MacroTools.postwalk(x -> rmLHSKwargs(x, kwsyms), initBlock)
    # Check if any kwarg variables show up anywhere in the init function after removing reassignment.
    MacroTools.postwalk(x -> walkKwArgs(x, kwsyms, usedKwargs), rmkwrhs)
    println(rmkwrhs)
    # Return the vector of kwarguments that are used in the initfunction
    return unique(usedKwargs)
end



