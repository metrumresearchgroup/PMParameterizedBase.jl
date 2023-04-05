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


# Check for multiple @init
function checkMultipleInit(modfn)
    init_counter = Int64[]
    MacroTools.postwalk(x -> @capture(x, @init init_) ? (push!(init_counter,1);init) : x, modfn)
    if length(init_counter) > 1
        error("Only a single @init block is allowed")
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
    elseif isexpr(x) && x.head == :macrocall && x.args[1] == Symbol("@IC")
        error("@IC definition outside of @init")
    elseif isexpr(x) && x.head == :macrocall && x.args[1] == Symbol("@repeated")
        error("@repeated definition outside of @init")
    elseif isexpr(x) && x.head == :macrocall && x.args[1] == Symbol("@constant")
        error("@constant definition outside of @init")   
    end
    return x
end
        
# Walk through @init block and check for out of place definitions
function walkAndCheckDefs(modfn)
    noInit = MacroTools.postwalk(x -> removeDefs(x), modfn)
    MacroTools.postwalk(x -> checkDefs(x), noInit)
end


# Check if there are any @ddt defined in @init. If so, throw an error.
function walkAndCheckDdtInInit(modfn)
    init = MacroTools.postwalk(x -> @capture(x, @init init_) ? init : nothing, modfn)
    MacroTools.postwalk(x -> checkDdtInInit(x), init)
end

function checkDdtInInit(x)
    # Check for @ddt macros in @init
    if isexpr(x) && x.head == :macrocall && x.args[1] == Symbol("@ddt")
        error("Derivative (@ddt) definition found inside @init. This is not supported.")
    end
    return x
end

## Check if a parameter exists in an if/for/while/try block
function checkForDefInBlock(x)
    if isexpr(x) && (x.head ∈ [:if, :for, :while, :try])
        MacroTools.postwalk(x -> @capture(x, @parameter _) ? error("Cannot define @parameter in if/for/while/try block") : x, x)
        MacroTools.postwalk(x -> @capture(x, @IC _) ? error("Cannot define @IC in if/for/while/try block") : x, x)
        MacroTools.postwalk(x -> @capture(x, @repeated _) ? error("Cannot define @repeated in if/for/while/try block") : x, x)
        MacroTools.postwalk(x -> @capture(x, @constant _) ? error("Cannot define @constant in if/for/while/try block") : x, x)
    end
    x
end


