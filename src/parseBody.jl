function parseBody(modfn, args)
    derivativeBlock = MdlBlock() # Create a MdlBlock to track which derivatives have been assigned.
    algebraicBlock = MdlBlock() # Create a MdlBlock to track which repeated algebraic expressions have been assigned.
    body = MacroTools.postwalk(x -> removeInit(x), modfn) # Remove @init block(s) from model. 
    body_NoDdt = MacroTools.postwalk(x -> removeDdt(x), body) # Remove @ddt definitions


    # Update the algebraicBlock properties by walking through the expression tree
    MacroTools.postwalk(x -> getAlgebraic(x, algebraicBlock), body_NoDdt) 

    # Update the derivativeBlock properties by walking through the body expression tree
    MacroTools.postwalk(x -> getDdt(body, derivativeBlock), body)


    
    return body, derivatives, dynamic_names


end


function removeInit(x)
    if isexpr(x) && x.head == :macrocall && x.args[1] == Symbol("@init")
        return nothing
    else
        return x
    end
end


function removeDdt(x)
    if isexpr(x) && x.head == :macrocall && x.args[1] == Symbol("@ddt")
        return nothing
    else
        return x
    end
end