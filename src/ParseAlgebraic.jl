function parsealgebraic(ex)
    ex = removemacros(ex)
    println(ex)
    AlgebraicBlock = MdlBlock(type=:Algebraic)
    AlgebraicBlock.Block = ex
    # println(AlgebraicBlock.Block)
    MacroTools.postwalk(x -> getGenericAssignment(x, AlgebraicBlock), AlgebraicBlock.Block)
    return AlgebraicBlock
end


