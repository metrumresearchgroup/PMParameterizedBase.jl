function parseBody(modfn, args)
    derivativeBlock = MdlBlock() # Create a MdlBlock to track which derivatives have been assigned.
    algebraicBlock = MdlBlock() # Create a MdlBlock to track which repeated algebraic expressions have been assigned.
    bodyBlock = MdlBlock() # Create a MdlBlock to hold everything but "@init"

    bodyBlock.Block = MacroTools.postwalk(x -> removeInit(x), modfn) # Remove @init block(s) from model. 

    # Strip header/function call from body
    bodyBlock.Block = MacroTools.postwalk(x -> (@capture(x, function f_(du_, u_, p_, t_, kwargs__) body_ end) ? body : x), MacroTools.longdef(bodyBlock.Block))

    algebraicBlock.Block = MacroTools.prewalk(x -> removeDdt(x), bodyBlock.Block) # Remove @ddt definitions
    # println(algebraicBlock.Block)

    # Update the algebraicBlock properties by walking through the expression tree
    MacroTools.prewalk(x -> getAssignment(x, algebraicBlock), algebraicBlock.Block) 
    # println(algebraicBlock.names)
    # println(algebraicBlock.LNNVector)

    # Update the derivativeBlock properties by walking through the body expression tree
    # MacroTools.postwalk(x -> getDdt(body, derivativeBlock), body)

    return bodyBlock


end



# Remove all "@ddt" definitions from the model
function removeDdt(x)
    if isexpr(x) && x.head == :macrocall && x.args[1] == Symbol("@ddt")
        return nothing
    else
        return x
    end
end