function parseBody(modfn, inputSym, arguments)
    bodyBlock = MdlBlock(type="Body") # Create a MdlBlock to hold everything but "@init"
    derivativeBlock = MdlBlock(type="@ddt", BlockSymbol = arguments[1]) # Create a MdlBlock to track which derivatives have been assigned.
    algebraicBlock = MdlBlock(type="Algebraic variable") # Create a MdlBlock to track which repeated algebraic expressions have been assigned.
    observedBlock = MdlBlock(type="@observed") #Create a MdlBlock to track observed quantities
    
    bodyBlock.Block = MacroTools.postwalk(x -> @capture(x, @init init_) ? nothing : x, modfn) # Remove @init block(s) from model. 
    
    model_function = MacroTools.postwalk(x -> getDdt(x, derivativeBlock, inputSym), bodyBlock.Block) # Update the parameterBlock properties by walking through the expression tree

    
    algebraicBlock.Block = MacroTools.postwalk(x -> @capture(x, @ddt ddt_) ? nothing : x, bodyBlock.Block)  # Remove @ddt definitions
    MacroTools.postwalk(x -> getGenericAssignment(x, algebraicBlock), algebraicBlock.Block)
    checkOOPDDT(algebraicBlock, arguments)

    # Grab Observed Values
    MacroTools.postwalk(x -> getObserved(x, observedBlock), bodyBlock.Block)


    push!(model_function.args[1].args, inputSym)
    bodyBlock.Block = model_function

    inputCA_elements = join(["$un = 0.0" for un in unique(derivativeBlock.names)], ", ")
    inputCA = string("ComponentArray($inputCA_elements)")
    inputCA = Meta.parse(inputCA)


    return bodyBlock, derivativeBlock, algebraicBlock, observedBlock, inputCA

end
