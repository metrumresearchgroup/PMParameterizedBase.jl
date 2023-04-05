# Get Generic Assignments
function getGenericAssignment(x, Block::MdlBlock)
    if typeof(x) == LineNumberNode
        Block.LNN = x
    end
    if isexpr(x) && ((@capture(x, a_ = b_) || @capture(x, a_ .= b_) || @capture(x, @__dot__ a_ = b_)))
            if isexpr(a)
                names = Symbol[]
                MacroTools.postwalk(x -> typeof(x) == Symbol ? (push!(names, x);x) : x, a);
                name = names[1] # Grab the first symbol. This will be the top-level derivative name
                push!(Block.names, name)
            else
                push!(Block.names, a)
            end
            push!(Block.LNNVector, Block.LNN)
        return nothing
    else
        return x
    end
end