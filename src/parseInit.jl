function parseInit(modfn, arguments)
    # println(modfn)
    walkAndCheckDefs(modfn) # Make sure there are no parameter or ic definitions outside of an @init block
    # Create an MdlBlock object for the initial block(s)
    initBlock = MdlBlock()
    MacroTools.postwalk(x -> getInit(x, initBlock), modfn) # Update the initBlock properties by walking through the expression tree
    # Create a MdlBlock object for the parameter block(s)
    parameterBlock = MdlBlock()
    MacroTools.postwalk(x -> getParam(x, parameterBlock), initBlock.Block) # Update the parameterBlock properties by walking through the expression tree

    # Create a MdlBlock object for the repeated block(s)
    repeatedBlock = MdlBlock()
    MacroTools.postwalk(x -> getRepeated(x, repeatedBlock), initBlock.Block) # Update the repeatedBlock properties by walking through the expression tree


    # Create a MdlBlock object for all other constant relationships in @init
    constantBlock = MdlBlock()
    constantIn = MacroTools.postwalk(x -> rmParams(x), initBlock.Block)
    constantIn = MacroTools.postwalk(x -> rmICs(x), constantIn)
    MacroTools.prewalk(x -> getAlgebraic(x, constantBlock), constantIn) # Update the constantBlock properties by walking through the expression tree


    # Create a MdlBlock object for state ic block(s)
    icBlock = MdlBlock()
    MacroTools.prewalk(x -> getIC(x, icBlock), initBlock.Block) # Update the icBlock properties by walking through the expression tree





    # Reparse init to add previous definition checks to @parameter, @IC, and @repeated blocks
    if model_warnings
        LNNAll = []
        for type in ["@parameter", "@IC", "@repeated"]
            warnBlock = WarnBlock()
            initBlock_tmp = MacroTools.postwalk(x -> findBlockAndInsertIsDefined(x, type, warnBlock), initBlock.Block)
            push!(LNNAll, WarnBlock)
            # initBlock.Block = initBlock_tmp
        end

        #    Also need to add to "everything else"
            warnAssignment = WarnBlock()
            initBlock_tmp = MacroTools.postwalk(x -> insertIsDefinedAssignment(x, "algebraic", warnAssignment, LNNAll), initBlock.Block)
            initBlock.Block = initBlock_tmp
            # println(LNNAssignment)

    end


 


    initBlock.Block = MacroTools.postwalk(x -> rmParamDef(x), initBlock.Block)
    initBlock.Block = MacroTools.postwalk(x -> rmICDef(x), initBlock.Block)
    initBlock.Block = MacroTools.postwalk(x -> rmRepeatedDef(x), initBlock.Block)
    return initBlock, parameterBlock, constantBlock, repeatedBlock, icBlock

end





