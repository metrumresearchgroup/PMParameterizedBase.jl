# Get variable assignments
function getAssignment(x, Block::MdlBlock)
    if typeof(x) == LineNumberNode # Check for LineNumberNodes and update MdlBlock LNN
        Block.LNN = x
    end

    if isexpr(x) && x.head ∈ [:if, :for, :while] # If in an if/for/while block update the node counter
        Block.node_counter += 1
    end
    if ((@capture(x, a_ = b_) || @capture(x, a_ .= b_) || @capture(x, @__dot__ a_ = b_))) # Check for variable assignment (i.e a = b)
        push!(Block.node_number, Block.node_counter) # Push node counter to MdlBlock
        push!(Block.names, a) # Push variable name to MdlBlock
        push!(Block.LNNVector, Block.LNN) # Push LNN to MdlBlock
        return nothing # If a variable is assigned, return nothing so walk doesn't go further down this branch. No need to "explore" futher.
    end
    return x
end

# Get only @init block(s) from @model
function getInit(x, Block::MdlBlock) # Check for LineNumberNodes and update MdlBlock LNN
    if typeof(x) == LineNumberNode
        Block.LNN = x
    end
    if @capture(x, @init init_) # If an @init block is found, push contents to MdlBlock.Block
        push!(Block.Block.args, init.args...)
        push!(Block.LNNVector, Block.LNN) # Push LNN to MdlBLock. This is probably unused...
    end
    return x
end


# Get only @parameter block(s) from @model
function getParam(x, Block::MdlBlock)
    if typeof(x) == LineNumberNode # Check for LineNumberNodes and update MdlBlock LNN
        Block.LNN = x
    end
    if @capture(x, @parameter param_) # If an @parameter block is found, push contents to MdlBlock.Block
        push!(Block.Block.args, param.args...) 
        MacroTools.postwalk(x -> getAssignment(x, Block), x) # Grab assignments within the @parameter block
    end
    return x
end

# Remove any @parameter definitions
function rmParams(x)
    if isexpr(x) && @capture(x, @parameter _)
        return nothing
    else
        return x
    end
end

# Remove any @variable definitions
function rmVariables(x)
    if isexpr(x) && @capture(x, @variable _)
        return nothing
    else
        return x
    end
end


# Get all algebraic defintions in a block
function getAlgebraic(x, Block::MdlBlock)
    if typeof(x) == LineNumberNode
        Block.LNN = x
    end
    if isexpr(x) 
        MacroTools.prewalk(x -> getAssignment(x, Block), x) # Grab all all assignments from a block that has @parameters and @variables removed
    end
    return x
end

# Get all @variable assignments
function getVariable(x, Block::MdlBlock)
    if typeof(x) == LineNumberNode # Check for LineNumberNodes and update MdlBlock LNN
        Block.LNN = x
    end
    if @capture(x, @variable var_) # If an @variable block is found, push contents to MdlBlock.Block
        push!(Block.Block.args, var.args...)
        MacroTools.prewalk(x -> getAssignment(x, Block), x) # Grab all assignments within the @variable block
    end
    return x
end

# Get all @dynamic assignments
function getConstant(x, Block::MdlBlock)
    if typeof(x) == LineNumberNode # Check for LineNumberNodes and update MdlBlock LNN
        Block.LNN = x
    end
    if @capture(x, @dynamic dynamic _)
        push!(Block.Block.args, dynamic.args...)
        MacroTools.prewalk(x -> getAssignment(x, Block), x)
    end
end


# Find overlap between variable assignment in two blocks. Warn if a variable of type 1 is redefined as type 2 or vice versa. If redefinition occurs, remove from unused corresponding MdlBlock list of names. 

function blockOverlap!(Block1::MdlBlock, Block2::MdlBlock, type1::Symbol, type2::Symbol)
    checked = Vector{Symbol}()
    rmBlock1 = Vector{Int64}()
    rmBlock2 = Vector{Int64}()
    for (i, (nm,b1LNN)) in enumerate(zip(Block1.names,Block1.LNNVector))
        if (nm in Block2.names) && (b1LNN ∉ Block2.LNNVector)
            j = findall(Block2.names .== nm)[1]
            b2LNN = Block2.LNNVector[j]
            if b2LNN.line > b1LNN.line && nm ∉ checked
                push!(checked, nm)
                push!(rmBlock1, i)
                @warn "Converting $type1 definition of $nm to a(n) $type2"
            elseif nm ∉ checked
                push!(checked, nm)
                push!(rmBlock2, j)
                @warn "Converting $type2 defintion of $nm to a(n) $type1"
            end
        end
    end
    deleteat!(Block1.names, rmBlock1)
    deleteat!(Block1.LNNVector, rmBlock1)
    deleteat!(Block2.names, rmBlock2)
    deleteat!(Block2.LNNVector, rmBlock2)
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



