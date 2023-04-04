function parseHeader(md)
    @capture(md, function f_(arguments__) body_ end)
    kwargs = Vector{Expr}()
    args = Vector{Symbol}()
    for arg in arguments
        if typeof(arg) == Expr && arg.head == :parameters
            for arg_i in arg.args
                if typeof(arg_i) == Symbol 
                    kwarg_i = arg_i
                    error("Keyword argument $kwarg_i requires a default value")
                elseif length(arg_i.args) != 2
                    kwarg_i = arg_i.args[1]
                    error("Keyword argument $kwarg_i requires a default value")
                end
            end                    
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