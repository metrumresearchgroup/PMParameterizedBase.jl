# Create a function to grab everything but state/IC/derivative declarations
function get_algebraic(modfn_in)
    modfn = copy(modfn_in)
    modfn_out = :()
    is_inplace = du_inplace(modfn)
    # Grab parameter names checking for inline or not...
    numArgs = 0
    duPos = 0
    if modfn.args[1].head == :call # Check if there is a function name or anonymous function and get position of "du"
        numArgs = length(modfn.args[1].args[2:end])
        duPos = 2
    elseif modfn.args[1].head == :tuple
        numArgs = length(modfn.args[1].args)
        duPos = 1
    else
        error("Unknown argument error")
    end

    if is_inplace
        duvec_sym_tmp = String(modfn.args[1].args[duPos]) # Grab "du" argument from determined "du" position
    else
        duvec_sym_tmp = String("D")
    end
    duvec_sym_tmp = string(duvec_sym_tmp)
    eval(:(pmxsymd = Symbol($duvec_sym_tmp)))
    i = 1
    for arg_outer in modfn.args
        j = 1
        inner_args = []
        state = Symbol()
        if arg_outer.head != :call
            for arg_inner in arg_outer.args
                if !contains(string(arg_inner), "@ddt") && !contains(string(arg_inner), "@mrstate") && !startswith(string(arg_inner), string(pmxsymd))

                    push!(inner_args,arg_inner)
                end
                j = j + 1
            end
            if length(inner_args)>0
                push!(modfn_out.args, inner_args)
                # modfn.args[i].args = inner_args
            end
            i = i + 1
        end
    end

    return modfn_out # Ignore function call. 
end

