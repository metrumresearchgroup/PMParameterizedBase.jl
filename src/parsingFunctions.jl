# Get variable assignments
function getAssignment(x, Block::MdlBlock)
    if typeof(x) == LineNumberNode # Check for LineNumberNodes and update MdlBlock LNN
        Block.LNN = x
    end
    if ((@capture(x, a_ = b_) || @capture(x, a_ .= b_) || @capture(x, @__dot__ a_ = b_))) # Check for variable assignment (i.e a = b)
        push!(Block.names, a) # Push variable name to MdlBlock
        push!(Block.LNNVector, Block.LNN) # Push LNN to MdlBlock
        return nothing
    else
        return x
    end
end



function insertIsDefinedBlock(x, type, WarnBlock)
    # If there are no line numbers because we are at the start of a definiton block, grab the one from just outside the block...
    if length(WarnBlock.LNNVector) == 0
        push!(WarnBlock.LNNVector, WarnBlock.LNN)
    end


    if (@capture(x, @isdefined _))
        return nothing
    elseif (@capture(x, @warn _))
        return nothing
    elseif typeof(x) == LineNumberNode
        WarnBlock.LNN = x
        push!(WarnBlock.LNNVector, x)
        return x
    elseif ((@capture(x, a_ = b_) || @capture(x, a_ .= b_) || @capture(x, @__dot__ a_ = b_))) # Check for variable assignment (i.e a = b)
        if typeof(a) != Expr
            local tval = string(type)
            local lval = string(a)
            local file = string(WarnBlock.LNN.file)
            local ln = string(WarnBlock.LNN.line)
            ret_expr = quote
                if @isdefined($a)
                    if $lval in keys(defTypeDict)
                        prev = defTypeDict[$lval]
                    else
                        prev = nothing
                    end
                    if prev == $tval
                        @warn (string("Overwriting ", $tval, " ", $lval, " at (or near) ", $file,":",$ln))
                    elseif !(isnothing(prev))
                        @warn (string("Declaring ", $lval, " as ", $tval, " at (or near) ", $file,":",$ln," overwrites previous definition as ", prev, ))
                    else
                        @warn (string("Declaring ", $lval, " as ", $tval, " at (or near) ", $file,":",$ln, " overwrites previous algebraic definition"))
                    end
                    defTypeDict[$lval] = $tval
                else
                    defTypeDict[$lval] = $tval
                end
                $x
            end
            for (i, arg) in enumerate(ret_expr.args)
                if typeof(arg) == LineNumberNode
                    ret_expr.args[i] = WarnBlock.LNN
                end
            end
            return ret_expr
        else
            return x
        end
    else
        return x
    end
end


function insertIsDefinedAssignment(x, type, WarnAssignment, LNNAll)
    if (@capture(x, @isdefined _))
        return nothing
    elseif (@capture(x, @warn _))
        return nothing
    elseif typeof(x) == LineNumberNode
        WarnAssignment.LNN = x
        push!(WarnAssignment.LNNVector, x)
        return x
    elseif ((@capture(x, a_ = b_) || @capture(x, a_ .= b_) || @capture(x, @__dot__ a_ = b_))) # Check for variable assignment (i.e a = b)
        if typeof(a) != Expr
            local tval = string(type)
            local lval = string(a)
            local file = string(WarnAssignment.LNN.file)
            local ln = string(WarnAssignment.LNN.line)
            local lnn = WarnAssignment.LNN
            if lnn ∉ LNNAll
                ret_expr = quote
                    if @isdefined($a)
                        if $lval in keys(defTypeDict)
                            prev = defTypeDict[$lval]
                        else
                            prev = nothing
                        end
                        if prev == $tval
                            @warn (string("Overwriting ", $tval, " ", $lval, " at (or near) ", $file,":",$ln))
                        elseif !(isnothing(prev))
                            @warn (string("Declaring ", $lval, " as ", $tval, " at (or near) ", $file,":",$ln," overwrites previous definition as ", prev, ))
                        else
                            @warn (string("Declaring ", $lval, " as ", $tval, " at (or near) ", $file,":",$ln, " overwrites previous algebraic definition"))
                        end
                    # else
                    #     defTypeDict[$lval] = $tval
                    end
                    $x
                end
                for (i, arg) in enumerate(ret_expr.args)
                    if typeof(arg) == LineNumberNode
                        ret_expr.args[i] = WarnAssignment.LNN
                    end
                end
                return ret_expr
                # return x
            else
                return x
            end
        else
            return x
        end
    else
        return x
    end
end



function findBlockAndInsertIsDefined(x, type, WarnBlock)
    if typeof(x) == LineNumberNode
        WarnBlock.LNN = x
    end
    if type == "@parameter"
        if isexpr(x) && @capture(x, @parameter in_)
            out = MacroTools.postwalk(x -> insertIsDefinedBlock(x, type, WarnBlock), in)
        else
            out = x
        end
    elseif type == "@repeated"
        if isexpr(x) && @capture(x, @repeated in_)
            out = MacroTools.postwalk(x -> insertIsDefinedBlock(x, type, WarnBlock), in)
        else
            out = x
        end
    elseif type == "@IC"
        if isexpr(x) && @capture(x, @IC in_)
            out = MacroTools.postwalk(x -> insertIsDefinedBlock(x, type, WarnBlock), in)
        else
            out = x
        end
    else
        out = x
    end
    return out
end







# Get only @init block(s) from @model
function getInit(x, Block::MdlBlock) # Check for LineNumberNodes and update MdlBlock LNN
    if typeof(x) == LineNumberNode
        Block.LNN = x
    end
    if @capture(x, @init init_) # If an @init block is found, push contents to MdlBlock.Block
        initargs = unblock.(init.args)
        push!(Block.Block.args, initargs...)
        Block.Block = init
        push!(Block.LNNVector, Block.LNN) # Push LNN to MdlBLock. This is probably unused...
        return nothing
    else
        return x
    end
end


# Remove the "@init" block from the model
function removeInit(x)
    if isexpr(x) && x.head == :macrocall && x.args[1] == Symbol("@init")
        return nothing
    else
        return x
    end
end


# Get only @parameter block(s) from @model
function getParam(x, Block::MdlBlock)
    if typeof(x) == LineNumberNode # Check for LineNumberNodes and update MdlBlock LNN
        Block.LNN = x
    end
    if @capture(x, @parameter param_) # If an @parameter block is found, push contents to MdlBlock.Block
        paramargs = unblock.(param.args)
        push!(Block.Block.args, paramargs...)
        MacroTools.postwalk(x -> getAssignment(x, Block), x) # Grab assignments within the @parameter block
        return nothing
    else
        return x
    end
end

# Remove any @parameter definitions
function rmParams(x)
    if isexpr(x) && @capture(x, @parameter _)
        return nothing
    else
        return x
    end
end



# Remove any @IC definitions
function rmICs(x)
    if isexpr(x) && @capture(x, @IC _)
        return nothing
    else
        return x
    end
end




# Get all constant defintions in a block
function getAlgebraic(x, Block::MdlBlock)
    if typeof(x) == LineNumberNode
        Block.LNN = x
    end
    if isexpr(x) 
        MacroTools.prewalk(x -> getAssignment(x, Block), x) # Grab all all assignments from a block that has @parameters and @ICs removed
        return nothing
    else
        return x
    end
end

# Get all @IC assignments
function getIC(x, Block::MdlBlock)
    if typeof(x) == LineNumberNode # Check for LineNumberNodes and update MdlBlock LNN
        Block.LNN = x
    end
    if @capture(x, @IC var_) # If an @IC block is found, push contents to MdlBlock.Block
        varargs = unblock.(var.args)
        push!(Block.Block.args, varargs...)
        MacroTools.prewalk(x -> getAssignment(x, Block), x) # Grab all assignments within the @IC block
        return nothing
    else
        return x
    end
end

# Get all @repeated assignments
function getRepeated(x, Block::MdlBlock)
    if typeof(x) == LineNumberNode # Check for LineNumberNodes and update MdlBlock LNN
        Block.LNN = x
    end
    if @capture(x, @repeated repeated _)
        repeatedargs = unblock.(repeated.args)
        push!(Block.Block.args, repeatedargs...)
        MacroTools.prewalk(x -> getAssignment(x, Block), x)
        return nothing
    else
        return x
    end
end


# get all @ddt assignments
function getDdt(x, Block::MdlBlock)
    if typeof(x) == LineNumberNode # Check for LineNumberNodes and update MdlBlock LNN
        Block.LNN = x
    end
    if @capture(x, @ddt repeated _)
        repeatedargs = unblock(repeated.args)
        push!(Block.Block.args, repeatedargs...)
        MacroTools.prewalk(x -> getAssignment(x, Block), x)
        return nothing
    else
        return x
    end
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
    # Remove reassignemt of kwarg values within the initFcn. We can ignore those when we go to parse all ics in the funcotin
    rmkwrhs = MacroTools.postwalk(x -> rmLHSKwargs(x, kwsyms), initBlock)
    # Check if any kwarg ics show up anywhere in the init function after removing reassignment.
    MacroTools.postwalk(x -> walkKwArgs(x, kwsyms, usedKwargs), rmkwrhs)
    # Return the vector of kwarguments that are used in the initfunction
    return unique(usedKwargs)
end


function rmParamDef(x)
    if isexpr(x) && @capture(x, @parameter pbody_)
        return pbody
    else
        return x
    end
end

function rmICDef(x)
    if isexpr(x) && @capture(x, @IC icbody_)
        return icbody
    else
        return x
    end
end

function rmRepeatedDef(x)
    if isexpr(x) && @capture(x, @repeated repbody_)
        return repbody
    else
        return x
    end
end
