# Check if the proper number of arguments are present in the ODE model definition
function checkArgs(args, kwargs)
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

# Remove @init definitions
function removeDefs(x)
    if isexpr(x) && x.head == :macrocall && x.args[1] == Symbol("@init")
        return nothing
    else
        return x
    end
end

# Check for definitions outside of @init block
function checkDefs(x)
    if isexpr(x) && x.head == :macrocall && x.args[1] == Symbol("@parameter")
        error("@parameter definiton outside of @init")
    elseif isexpr(x) && x.head == :macrocall && x.args[1] == Symbol("@variable")
        error("@variable definition outside of @init")
    elseif isexpr(x) && x.head == :macrocall && x.args[1] == Symbol("@dynamic")
        error("@dynamic definition outside of @init")
    end
    return x
end
        
# Walk through @init block and check for out of place definitions
function walkAndCheckDefs(modfn)
    noInit = MacroTools.postwalk(x -> removeDefs(x), modfn)
    MacroTools.postwalk(x -> checkDefs(x), noInit)
end


# Check if there are any @ddt defined in @init. If so, throw an error.
function checkDdtInInit(x)
    # Check for @ddt macros in @init
    if isexpr(x) && x.head == :macrocall && x.args[1] == Symbol("@ddt")
        error("Derivative (@ddt) definition found inside @init. This is not supported.")
    end
    return x
end

# Walk through @init to check for @ddt 
function walkAndCheckDdt(init_block)
    # Check for @ddt macros in @init
    MacroTools.postwalk(x -> checkDdtInInit(x), init_block)
end
    

# Check for redefintion of @parameter or @variable
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
                elseif type == :dynamic
                    @warn "@dynamic $n is defined multiple times. Using RHS from the last defintion"
                end
            end
        end
    end
end







