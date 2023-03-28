function getAssignment(x, Block::MdlBlock)
    if typeof(x) == LineNumberNode
        Block.LNN = x
    end

    if isexpr(x) && x.head ∈ [:if, :for, :while]
        Block.node_counter += 1
    end
    if ((@capture(x, a_ = b_) || @capture(x, a_ .= b_) || @capture(x, @__dot__ a_ = b_)))
        push!(Block.node_number, Block.node_counter)
        push!(Block.names, a)
        push!(Block.LNNVector, Block.LNN)
        return nothing
    end
    return x
end


function getInit(x, Block::MdlBlock)
    if typeof(x) == LineNumberNode
        Block.LNN = x
    end
    if @capture(x, @init init_)
        push!(Block.Block.args, init.args...)
        push!(Block.LNNVector, Block.LNN)
    end
    return x
end

function getParam(x, Block::MdlBlock)
    if typeof(x) == LineNumberNode
        Block.LNN = x
    end
    if @capture(x, @parameter param_)
        push!(Block.Block.args, param.args...)
        MacroTools.postwalk(x -> getAssignment(x, Block), x)
    end
    return x
end

function rmParams(x)
    if isexpr(x) && @capture(x, @parameter _)
        return nothing
    else
        return x
    end
end

function rmVariables(x)
    if isexpr(x) && @capture(x, @variable _)
        return nothing
    else
        return x
    end
end



function getStatic(x, Block::MdlBlock)
    # println(x)
    if typeof(x) == LineNumberNode
        Block.LNN = x
    end
    if isexpr(x) 
        MacroTools.prewalk(x -> getAssignment(x, Block), x)
    end
    return x
end

function getVariable(x, Block::MdlBlock)
    if typeof(x) == LineNumberNode
        Block.LNN = x
    end
    if @capture(x, @variable var_)
        push!(Block.Block.args, var.args...)
        MacroTools.prewalk(x -> getAssignment(x, Block), x)
    end
    return x
end



function filterStatic!(staticBlock::MdlBlock, pBlock::MdlBlock)
    checked = Vector{Symbol}()
    rmStatic = Vector{Int64}()
    rmP = Vector{Int64}()
    for (i, (nm,sLNN)) in enumerate(zip(staticBlock.names,staticBlock.LNNVector))
        if (nm in pBlock.names) && (sLNN ∉ pBlock.LNNVector)
            j = findall(pBlock.names .== nm)[1]
            pLNN = pBlock.LNNVector[j]
            if pLNN.line > sLNN.line && nm ∉ checked
                push!(checked, nm)
                push!(rmStatic, i)
                @warn "Converting static definition of $nm to a @parameter"
            elseif nm ∉ checked
                push!(checked, nm)
                push!(rmP, j)
                @warn "Converting @parameter $nm to a static variable"
            end
        end
    end
    deleteat!(staticBlock.names, rmStatic)
    deleteat!(staticBlock.LNNVector, rmStatic)
    deleteat!(pBlock.names, rmP)
    deleteat!(pBlock.LNNVector, rmP)
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
    # Return the vector of kwarguments that are used in the initfunction
    return unique(usedKwargs)
end



