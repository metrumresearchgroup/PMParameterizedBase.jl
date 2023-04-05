
# Get only @ddt block(s) from @model
function getDdt(x, Block::MdlBlock, inputSym)
    if typeof(x) == LineNumberNode # Check for LineNumberNodes and update MdlBlock LNN
        Block.LNN = x
    end
    if @capture(x, @ddt ddt_) # If an @ddt block is found, push contents to MdlBlock.Block
        if typeof(ddt) == Symbol
            LNN = Block.LNN
            error("Parameter definition must take form of a = b at $(LNN.file):$(LNN.line)")
            return nothing
        else
            # ddtargs = unblock.(ddt.args)
            # push!(Block.Block.args, ddtargs...)
            ddt_mod = MacroTools.postwalk(x -> getDdtFromBlock(x, Block, inputSym), ddt) # Grab assignments within the @ddt block
            return ddt_mod
        end
    else
        return x
    end
end

# Get assignments within @ddt
function getDdtFromBlock(x, derivBlock, inputSym)
    if typeof(x) == Symbol
        return x
    end
    if isexpr(x) && ((@capture(x, a_ = b_) || @capture(x, a_ .= b_) || @capture(x, @__dot__ a_ = b_)))
        if isexpr(a)
            LNN = derivBlock.LNN
            error("@ddt definition must be of the form a = b. Cannot use index or field/property at $(LNN.file):$(LNN.line)")
        else
            # Check if a is an expression. If so, use postwalk to get 
            if isexpr(a)
                dnames = Symbol[]
                MacroTools.postwalk(x -> typeof(x) == Symbol ? (push!(dnames, x);x) : x, a);
                dname = dnames[1] # Grab the first symbol. This will be the top-level derivative name
                push!(derivativeBlock.names, dname)
            else
                push!(derivBlock.names, a)
            end
            push!(derivBlock.LNNVector, derivBlock.LNN)
            lhs = b
            inputAdd = Expr(:.)
            push!(inputAdd.args,inputSym)
            if typeof(a) == Symbol 
                push!(inputAdd.args, QuoteNode(a))
            else
                push!(inputAdd.args, a)
            end
            lhs = Expr(:call, :+, lhs, inputAdd)
            out = Meta.parse(string(derivBlock.BlockSymbol, ".", a, " = ", lhs))
            return out
        end
    elseif typeof(x) == Symbol
        LNN = derivBlock.LNN
        # println(x)
        error("Unrecognized @ddt definition. Must be a variable assignment (i.e a = b) at $(LNN.file):$(LNN.line)")
    else
        if typeof(x) == LineNumberNode
            derivBlock.LNN = x
    end 
        return x
    end
end



# Get only @constant block(s) from @model
function getObserved(x, Block::MdlBlock)
    if typeof(x) == LineNumberNode # Check for LineNumberNodes and update MdlBlock LNN
        Block.LNN = x
    end
    if @capture(x, @observed observed_) # If an @parameter block is found, push contents to MdlBlock.Block
        if typeof(observed) == Symbol
            LNN = Block.LNN
            error("@constant definition must take form of a = b at $(LNN.file):$(LNN.line)")
            return nothing
        else
            obsargs = unblock.(observed.args)
            push!(Block.Block.args, obsargs...)
            MacroTools.prewalk(x -> getObservedFromBlock(x, Block), observed) # Grab assignments within the @observed block
            return nothing
        end
    else
        return x
    end
end


function getObservedFromBlock(x, obsBlock)
    if isexpr(x) && ((@capture(x, a_ = b_) || @capture(x, a_ .= b_) || @capture(x, @__dot__ a_ = b_)))
        if isexpr(a)
            LNN = obsBlock.LNN
            error("@observed definition must be of the form a = b. Cannot use index or field/property at $(LNN.file):$(LNN.line). Please create an intermediate observed variable if you wish to view a slice of an array or property")
        else
            push!(obsBlock.names, a)
            push!(obsBlock.LNNVector, obsBlock.LNN)

            return nothing
        end
    elseif typeof(x) == Symbol
        LNN = obsBlock.LNN
        error("Unrecognized @observed definition. Must be a variable assignment (i.e a = b) at $(LNN.file):$(LNN.line)")
    else
        if typeof(x) == LineNumberNode
            obsBlock.LNN = x
        end
        return x
    end
end


function insertParameters(bodyBlock, parameterBlock, arguments)
    psym = arguments[3]
    body = bodyBlock.Block
    for (i,p) in enumerate(parameterBlock.names)
        expr_in = :($p = $psym.$p)
        insert!(body.args[2].args, 2+(i-1), expr_in)
    end
    bodyBlock.Block = body
end


function insertStates(bodyBlock, icBlock, arguments)
    usym = arguments[2]
    body = bodyBlock.Block
    for (i,u) in enumerate(icBlock.names)
        expr_in = :($u = $usym.$u)
        insert!(body.args[2].args, 2+(i-1), expr_in)
    end
    bodyBlock.Block = body
end