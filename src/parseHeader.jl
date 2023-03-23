function parseHeader(md)
    @capture(md, function f_(arguments__) body_ end)
    kwargs = Vector{Expr}()
    args = Vector{Symbol}()
    for arg in arguments
        if typeof(arg) == Expr && arg.head == :parameters
            push!(kwargs, arg)
        elseif typeof(arg) == Symbol
            push!(args,arg)
        else
            "Unknown error in header argument $arg"
        end
    end
    checkArgs(args, kwargs)
    return args, kwargs, f, arguments, body
end