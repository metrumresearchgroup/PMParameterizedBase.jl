function parseInit(modfn, arguments)
    walkAndCheckDefs(modfn) # Make sure there are no @parameter, @ic, @repeated or @constant definitions outside of an @init block
    checkMultipleInit(modfn)
    walkAndCheckDdtInInit(modfn)

    # Create an MdlBlock object for the initial block(s)
    initBlock = MdlBlock(type = "@init")
    MacroTools.postwalk(x -> getInit(x, initBlock), modfn) # Update the initBlock properties by walking through the expression tree


    ## Check if a parameter exists in an if/for/while/try block
    MacroTools.postwalk(x -> checkForDefInBlock(x), initBlock.Block)

    # Create a MdlBlock object for the parameter block(s)
    parameterBlock = MdlBlock(type = "@parameter",BlockSymbol = arguments[3])
    MacroTools.postwalk(x -> getParam(x, parameterBlock), initBlock.Block) # Update the parameterBlock properties by walking through the expression tree


    # Create a MdlBlock object for the IC(s)
    icBlock = MdlBlock(type = "@IC",BlockSymbol = arguments[2])
    MacroTools.postwalk(x -> getIC(x, icBlock), initBlock.Block)

    # Create a MdlBlock object for repeated variables
    repeatedBlock = MdlBlock(type = "@repeated")
    MacroTools.postwalk(x -> getRepeated(x, repeatedBlock), initBlock.Block)

    # Create a MdlBlock object for constant variables
    constantBlock = MdlBlock(type = "@constant")
    MacroTools.postwalk(x -> getConstants(x, constantBlock), initBlock.Block)


    # Remove all Macros the @init block and grab variable assignments
    initAssignment = MdlBlock(type="Initial algebraic variable")
    initAssignment.Block = MacroTools.postwalk(x -> @capture(x, @_ __) ? nothing : x, initBlock.Block)
    MacroTools.postwalk(x -> getGenericAssignment(x, initAssignment), initAssignment.Block)


    # Check if there are any repeated parameters
    variableRepeat(parameterBlock)
    # Check if there are any repeated ICs
    variableRepeat(icBlock)
    # Check if there are any repeated repeated
    variableRepeat(repeatedBlock)
    # Check if there are any repeated constants
    variableRepeat(constantBlock)


    # Check for @parameter, @ICs overlap
    variableOverlap(parameterBlock, icBlock)
    # Check for @parameter, @repeated overlap
    variableOverlap(parameterBlock, repeatedBlock)
    # Check for @paramter, @constant overlap
    variableOverlap(parameterBlock, constantBlock)

    # Check for @IC, @repeated overlap
    variableOverlap(icBlock, repeatedBlock)
    # Check for @IC, @constant overlap
    variableOverlap(icBlock, constantBlock)

     # Check for @repeated, @constant overlap
     variableOverlap(repeatedBlock, constantBlock)



     # Check for initAssignment, @parameter overlap
     variableOverlap(initAssignment, parameterBlock)
     # Check for initAssignment, @IC overlap
     variableOverlap(initAssignment, icBlock)
     # Check for initAssignment, @repeated overlap
     variableOverlap(initAssignment, repeatedBlock)
     # Check for initAssignment, @constant overlap
     variableOverlap(initAssignment, constantBlock)

    return initBlock, parameterBlock, icBlock, repeatedBlock, constantBlock, initAssignment
end 





