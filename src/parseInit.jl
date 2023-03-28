Base.@kwdef mutable struct MdlBlock
    node_counter::Int64 = 0
    node_number::Vector{Int64} = Vector{Int64}()
    names::Vector{Symbol} = Vector{Symbol}()
    Block::Expr = Expr(:block)
    LNN::LineNumberNode = LineNumberNode(0)
    LNNVector::Vector{LineNumberNode} = Vector{LineNumberNode}()
end


function parseInit(modfn, arguments)
    walkAndCheckDefs(modfn) # Make sure there are no parameter or variable definitions outside of an @init block
    # Create an MdlBlock object for the initial block(s)
    initBlock = MdlBlock()
    MacroTools.postwalk(x -> getInit(x, initBlock), modfn) # Update the initBlock properties by walking through the expression tree
    
    # Create a MdlBlock object for the parameter block(s)
    parameterBlock = MdlBlock()
    MacroTools.postwalk(x -> getParam(x, parameterBlock), initBlock.Block) # Update the initBlock properties by walking through the expression tree

    # Check if any parameters are redefined and throw a warning, if so.
    checkRedefinition(parameterBlock; type = :parameter)

    # Create a MdlBlock object for all other algebraic relationships in @init
    staticBlock = MdlBlock()
    staticIn = MacroTools.postwalk(x -> rmParams(x), initBlock.Block)
    staticIn = MacroTools.postwalk(x -> rmVariables(x), staticIn)
    MacroTools.prewalk(x -> getStatic(x, staticBlock), staticIn) # Update the initBlock properties by walking through the expression tree

    # Throw warnings for reassignment of parameters to algebraic expressions and vice versa
    # Filter out un-needed parameters/algebraic expressions based on re-assignment
    filterStatic!(staticBlock, parameterBlock)

    # Create a MdlBlock object for state variable block(s)
    variableBlock = MdlBlock()
    MacroTools.prewalk(x -> getVariable(x, variableBlock), initBlock.Block) # Update the initBlock properties by walking through the expression tree
    
    # Check if any variables are redefined and throw a warning, if so.
    checkRedefinition(variableBlock; type = :variable) 

    # NEED TO CHECK FOR PARAMETER/STATIC/VARIABLE OVERLAP!
    

    return nothing

end





