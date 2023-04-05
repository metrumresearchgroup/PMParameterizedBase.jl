
# Get only @init block(s) from @model
function getInit(x, Block::MdlBlock) # Check for LineNumberNodes and update MdlBlock LNN
    if typeof(x) == LineNumberNode
        Block.LNN = x
        push!(Block.LNNVector, x)
    end
    if @capture(x, @init init_) # If an @init block is found, push contents to MdlBlock.Block
        initargs = unblock.(init.args)
        push!(Block.Block.args, initargs...)
        Block.Block = init
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
        if typeof(param) == Symbol
            LNN = Block.LNN
            error("Parameter definition must take form of a = b at $(LNN.file):$(LNN.line)")
            return nothing
        else
            paramargs = unblock.(param.args)
            push!(Block.Block.args, paramargs...)
            MacroTools.prewalk(x -> getParamsFromBlock(x, Block), param) # Grab assignments within the @parameter block
            return nothing
        end
    else
        return x
    end
end

# Get assignments within @parameters
function getParamsFromBlock(x, pBlock)
    if isexpr(x) && ((@capture(x, a_ = b_) || @capture(x, a_ .= b_) || @capture(x, @__dot__ a_ = b_)))
        if isexpr(a)
            LNN = pBlock.LNN
            error("@parameter definition must be of the form a = b. Cannot use index or field/property at $(LNN.file):$(LNN.line)")
        else
            push!(pBlock.names, a)
            push!(pBlock.LNNVector, pBlock.LNN)
            return nothing
        end
    elseif typeof(x) == Symbol
        LNN = pBlock.LNN
        error("Unrecognized @parameter definition. Must be a variable assignment (i.e a = b) at $(LNN.file):$(LNN.line)")
    else
        if typeof(x) == LineNumberNode
            pBlock.LNN = x
        end
        return x
    end
end






# Get only @IC block(s) from @model
function getIC(x, Block::MdlBlock)
    if typeof(x) == LineNumberNode # Check for LineNumberNodes and update MdlBlock LNN
        Block.LNN = x
    end
    if @capture(x, @IC IC_) # If an @parameter block is found, push contents to MdlBlock.Block
        if typeof(IC) == Symbol
            LNN = Block.LNN
            error("@IC definition must take form of a = b at $(LNN.file):$(LNN.line)")
            return nothing
        else
            ICargs = unblock.(IC.args)
            push!(Block.Block.args, ICargs...)
            MacroTools.prewalk(x -> getICsFromBlock(x, Block), IC) # Grab assignments within the @parameter block
            return nothing
        end
    else
        return x
    end
end



function getICsFromBlock(x, icBlock)
    if isexpr(x) && ((@capture(x, a_ = b_) || @capture(x, a_ .= b_) || @capture(x, @__dot__ a_ = b_)))
        if isexpr(a)
            LNN = icBlock.LNN
            error("@IC definition must be of the form a = b. Cannot use index or field/property at $(LNN.file):$(LNN.line)")
        else
            push!(icBlock.names, a)
            push!(icBlock.LNNVector, icBlock.LNN)
            return nothing
        end
    elseif typeof(x) == Symbol
        LNN = icBlock.LNN
        error("Unrecognized @IC definition. Must be a variable assignment (i.e a = b) at $(LNN.file):$(LNN.line)")
    else
        if typeof(x) == LineNumberNode
            icBlock.LNN = x
        end
        return x
    end
end



# Get only @repeated block(s) from @model
function getRepeated(x, Block::MdlBlock)
    if typeof(x) == LineNumberNode # Check for LineNumberNodes and update MdlBlock LNN
        Block.LNN = x
    end
    if @capture(x, @repeated rep_) # If an @parameter block is found, push contents to MdlBlock.Block
        if typeof(rep) == Symbol
            LNN = Block.LNN
            error("@repeated definition must take form of a = b at $(LNN.file):$(LNN.line)")
            return nothing
        else

            repargs = unblock.(rep.args)
            push!(Block.Block.args, repargs...)
            MacroTools.prewalk(x -> getRepeatedFromBlock(x, Block), rep) # Grab assignments within the @parameter block
            return nothing
        end
    else
        return x
    end
end



function getRepeatedFromBlock(x, repBlock)
    if isexpr(x) && ((@capture(x, a_ = b_) || @capture(x, a_ .= b_) || @capture(x, @__dot__ a_ = b_)))
        if isexpr(a)
            LNN = repBlock.LNN
            error("@repeated definition must be of the form a = b. Cannot use index or field/property at $(LNN.file):$(LNN.line)")
        else
            push!(repBlock.names, a)
            push!(repBlock.LNNVector, repBlock.LNN)
            return nothing
        end
    elseif typeof(x) == Symbol
        LNN = repBlock.LNN
        error("Unrecognized @repeated definition. Must be a variable assignment (i.e a = b) at $(LNN.file):$(LNN.line)")
    else
        if typeof(x) == LineNumberNode
            repBlock.LNN = x
        end
        return x
    end
end

# Get only @constant block(s) from @model
function getConstants(x, Block::MdlBlock)
    if typeof(x) == LineNumberNode # Check for LineNumberNodes and update MdlBlock LNN
        Block.LNN = x
    end
    if @capture(x, @constant constant_) # If an @parameter block is found, push contents to MdlBlock.Block
        if typeof(constant) == Symbol
            LNN = Block.LNN
            error("@constant definition must take form of a = b at $(LNN.file):$(LNN.line)")
            return nothing
        else
            constargs = unblock.(constant.args)
            push!(Block.Block.args, constargs...)
            MacroTools.prewalk(x -> getConstantsFromBlock(x, Block), constant) # Grab assignments within the @parameter block
            return nothing
        end
    else
        return x
    end
end


function getConstantsFromBlock(x, constBlock)
    if isexpr(x) && ((@capture(x, a_ = b_) || @capture(x, a_ .= b_) || @capture(x, @__dot__ a_ = b_)))
        if isexpr(a)
            LNN = constBlock.LNN
            error("@constant definition must be of the form a = b. Cannot use index or field/property at $(LNN.file):$(LNN.line)")
        else
            push!(constBlock.names, a)
            push!(constBlock.LNNVector, constBlock.LNN)

            return nothing
        end
    elseif typeof(x) == Symbol
        LNN = constBlock.LNN
        error("Unrecognized @constant definition. Must be a variable assignment (i.e a = b) at $(LNN.file):$(LNN.line)")
    else
        if typeof(x) == LineNumberNode
            constBlock.LNN = x
        end
        return x
    end
end








