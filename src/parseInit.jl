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


    # Create a MdlBlock object for the dynamic block(s)
    dynamicBlock = MdlBlock()
    MacroTools.postwalk(x -> getDynamic(x, dynamicBlock), initBlock.Block)

    # Check if any dynamics are redefined and throw a warning, if so
    checkRedefinition(dynamicBlock; type = :dynamic)


    # Create a MdlBlock object for all other algebraic relationships in @init
    algebraicBlock = MdlBlock()
    algebraicIn = MacroTools.postwalk(x -> rmParams(x), initBlock.Block)
    algebraicIn = MacroTools.postwalk(x -> rmVariables(x), algebraicIn)
    MacroTools.prewalk(x -> getAlgebraic(x, algebraicBlock), algebraicIn) # Update the initBlock properties by walking through the expression tree

    # TODO: Need to think a bit more about the order of these...
    # Throw warnings for reassignment of parameters to algebraic expressions and vice versa
    # Filter out un-needed parameters/algebraic expressions based on re-assignment
    blockOverlap!(algebraicBlock, parameterBlock,:algebraic, Symbol("@parameter"))

    # Throw warnings for reassignemt of parameters to dynamics and vice versa
    # Filter out un-needed parameters/dynamic expressions based on re-assignment
    blockOverlap!(parameterBlock, dynamicBlock, Symbol("@parameter"), Symbol("@dynamic"))

    # Throw warnings for reassignment of algebraic expressions to dynamic and vice versa
    # Filter out un-needed algebraics/dynamic expressions based on re-assignment
    blockOverlap!(algebraicBlock, dynamicBlock, :algebraic, Symbol("@dynamic"))

    # Create a MdlBlock object for state variable block(s)
    variableBlock = MdlBlock()
    MacroTools.prewalk(x -> getVariable(x, variableBlock), initBlock.Block) # Update the initBlock properties by walking through the expression tree
    
    # Check if any variables are redefined and throw a warning, if so.
    checkRedefinition(variableBlock; type = :variable) 


    # Throw warnings for reassignment of variable expressions to dynamic and vice versa
    # Filter out un-needed variables/dynamic expressions based on re-assignment
    blockOverlap!(variableBlock, dynamicBlock, Symbol("@variable"), Symbol("@dynamic"))

    # Throw warnings for reassignment of variable expressions to parameters and vice versa
    # Filter out un-needed variables/dynamic expressions based on re-assignment
    blockOverlap!(variableBlock, parameterBlock, Symbol("@variable"), Symbol("@parameter"))

    # Throw warnings for reassignment of variable expressions to algebraic expressions and vice versa
    # Filter out un-needed variables/dynamic expressions based on re-assignment
    blockOverlap!(variableBlock, algebraicBlock, Symbol("@variable"), :algebraic)

    
    

    return nothing

end





