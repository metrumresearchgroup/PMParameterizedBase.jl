function checkArgs(args,kwargs)
    if (length(args)) < 4
        if length(args)>0
            error(string.("Missing arguments. Function call should include (du, u, p, t; kwargs), only. Current arguments: ", join(args, ", "," and")))
        else
            error("No arguments provided. Function call should be (du, u, p, t)")
        end
    elseif (length(args)) > 4
        error(string.("Too many arguments. Function call should include (du, u, p, t), only. Current arguments: ", join(args, ", "," and"), ". Please separate kwargs with a ';'"))
    end
end

function removeDefs(x)
    if isexpr(x) && x.head == :macrocall && x.args[1] == Symbol("@init")
        return nothing
    else
        return x
    end
end

function checkDefs(x)
    if isexpr(x) && x.head == :macrocall && x.args[1] == Symbol("@parameter")
        error("@parameter definiton outside of @init")
    elseif isexpr(x) && x.head == :macrocall && x.args[1] == Symbol("@variable")
        error("@variable definition outside of @init")
    elseif isexpr(x) && x.head == :macrocall && x.args[1] == Symbol("@constant")
        error("@constant definition outside of @init")
    end
    return x
end
        
function walkAndCheckDefs(modfn)
    noInit = MacroTools.postwalk(x -> removeDefs(x), modfn)
    MacroTools.postwalk(x -> checkDefs(x), noInit)
end



function checkDdtInInit(x)
    # Check for @ddt macros in @init
    if isexpr(x) && x.head == :macrocall && x.args[1] == Symbol("@ddt")
        error("Derivative (@ddt) definition found inside @init. This is not supported.")
    end
    return x
end

function walkAndCheckDdt(init_block)
    # Check for @ddt macros in @init
    MacroTools.postwalk(x -> checkDdtInInit(x), init_block)
end
    

function checkRedefinition(Block::MdlBlock; type=:parameter)
    nUnique = unique(Block.names)
    for n in nUnique
        idxs = findall(n .== Block.names)
        if length(idxs) >= 2
            if !allequal(Block.node_number[idxs])
                if type == :parameter
                    @warn "@parameter $n is defined multiple times. Using value from last definition"
                elseif type == :variable
                    @warn "@variable $n is defined multiple times. Using value from the last definition as the initial condition"
                end
            end
        end
    end
end







