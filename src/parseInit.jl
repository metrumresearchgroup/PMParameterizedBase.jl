function parseInit(modfn, arguments)
    walkAndCheckDefs(modfn) # Make sure there are no parameter or ic definitions outside of an @init block
    # Create an MdlBlock object for the initial block(s)
    initBlock = MdlBlock()
    MacroTools.postwalk(x -> getInit(x, initBlock), modfn) # Update the initBlock properties by walking through the expression tree
    
    # Create a MdlBlock object for the parameter block(s)
    parameterBlock = MdlBlock()
    MacroTools.postwalk(x -> getParam(x, parameterBlock), initBlock.Block) # Update the parameterBlock properties by walking through the expression tree

    # Check if any parameters are redefined and throw a warning, if so.
    checkRedefinition(parameterBlock; type = :parameter)


    # Create a MdlBlock object for the repeated block(s)
    repeatedBlock = MdlBlock()
    MacroTools.postwalk(x -> getRepeated(x, repeatedBlock), initBlock.Block) # Update the repeatedBlock properties by walking through the expression tree

    # Check if any repeateds are redefined and throw a warning, if so
    checkRedefinition(repeatedBlock; type = :repeated)


    # Create a MdlBlock object for all other constant relationships in @init
    constantBlock = MdlBlock()
    constantIn = MacroTools.postwalk(x -> rmParams(x), initBlock.Block)
    constantIn = MacroTools.postwalk(x -> rmICs(x), constantIn)
    MacroTools.prewalk(x -> getAlgebraic(x, constantBlock), constantIn) # Update the constantBlock properties by walking through the expression tree

    # TODO: Need to think a bit more about the order of these...
    # Throw warnings for reassignment of parameters to constant expressions and vice versa
    # Filter out un-needed parameters/constant expressions based on re-assignment
    blockOverlap!(constantBlock, parameterBlock,:constant, Symbol("@parameter"))

    # Throw warnings for reassignemt of parameters to repeateds and vice versa
    # Filter out un-needed parameters/repeated expressions based on re-assignment
    blockOverlap!(parameterBlock, repeatedBlock, Symbol("@parameter"), Symbol("@repeated"))

    # Throw warnings for reassignment of constant expressions to repeated and vice versa
    # Filter out un-needed constants/repeated expressions based on re-assignment
    blockOverlap!(constantBlock, repeatedBlock, :constant, Symbol("@repeated"))

    # Create a MdlBlock object for state ic block(s)
    icBlock = MdlBlock()
    MacroTools.prewalk(x -> getIC(x, icBlock), initBlock.Block) # Update the icBlock properties by walking through the expression tree


    # Check if any ics are redefined and throw a warning, if so.
    checkRedefinition(icBlock; type = :ic) 


    # Throw warnings for reassignment of ic expressions to repeated and vice versa
    # Filter out un-needed ics/repeated expressions based on re-assignment
    blockOverlap!(icBlock, repeatedBlock, Symbol("@IC"), Symbol("@repeated"))

    # Throw warnings for reassignment of ic expressions to parameters and vice versa
    # Filter out un-needed ics/repeated expressions based on re-assignment
    blockOverlap!(icBlock, parameterBlock, Symbol("@IC"), Symbol("@parameter"))

    # Throw warnings for reassignment of ic expressions to constant expressions and vice versa
    # Filter out un-needed ics/repeated expressions based on re-assignment
    blockOverlap!(icBlock, constantBlock, Symbol("@IC"), :constant)

    
    

    return initBlock, parameterBlock, constantBlock, repeatedBlock, icBlock

end





