using PMxSim

# macro mrparam(pin)
#     parray = []
#     pnames = []
#     pvals = []
#     println(pin)
#     if pin.head == :block
#         parray = pin.args
#     elseif pin.head == :(=)
#         parray = [pin]
#     else
#         error("Unrecognized parameter definition")
#     end
#     qts = quote
#           end
#     qtsv = []
#     for p in parray
#         if typeof(p) != LineNumberNode
#             pnam = p.args[1]
#             pval = p.args[2]
#             push!(pnames, pnam)
#             push!(pvals, pval)
#             qt = :($pnam = $psym.$pnam)
#             push!(qtsv, qt)
#         else
#             push!(qtsv, p)
#         end
#     end
#     return qtsv, pnames, pvals
# end

function walkParam(x)
    retcode = false
    if isexpr(x) && (@capture(x, _ = _) || @capture(x, _ .= _) || @capture(x, @__dot__ _ = _ )) # Make sure x is an expression, and then check for parameter assigment with "=", ".=" or "@. parameter = value"
        pn = x.args[1]
        pv = x.args[2]
        out = :($pn = $psym.$pn)
        :(push!(pnames, pn))
        :(push!(pvals, pv))
        return out
    else
        return x
    end
end

macro mrparam(min)
    out = MacroTools.postwalk(x -> walkParam(x), min)
    # pblock = out
    return out#, pnames, pvals
end


macro mrstate(sin)
    sarray = []
    snames = []
    svals = []
    if sin.head == :block
        sarray = sin.args
    elseif sin.head == :(=)
        sarray = [sin]
    else
        error("Unrecognized state definition")
    end
    qts = quote
    end
    qtsv = []
    for s in sarray
        if typeof(s) != LineNumberNode
            snam = s.args[1]
            sval = s.args[2]
            push!(snames, snam)
            push!(svals, sval)
            qt = :($snam = $usym.$snam)
            push!(qtsv, qt)
        else
            push!(qtsv, s)
        end
    end
    return qtsv, snames, svals
end


# TODO: Add an @ignore macro for parsing @ddt if we want to 'ignore', or not include the output of this state in the solution. Might be nice to be able to pare down solution to only things we are interested in.
macro ddt(din)
    darray = []
    dnames = []
    dvals = []
    if din.head == :block
        darray = din.args
    elseif din.head == :(=)
        darray = [din]
    else
        error("Unrecognized derivative definition")
    end
    qts = quote
    end
    qtsv = []
    for d in darray
        if typeof(d) != LineNumberNode
            dnam = d.args[1]
            dval = d.args[2]
            push!(dnames, dnam)
            push!(dvals, dval)
            qt = :($dusym.$dnam = $dval + $inputsym.$dnam)
            push!(qtsv, qt)
        else
            push!(qtsv, s)
        end
    end
    return qtsv, dnames, dvals
end

macro constant(min)
    marray = []
    mnames = []
    mvals = []
    if min.head == :block
        marray = min.args
    elseif min.head == :(=)
        marray = [min]
    else
        error("Unrecognized expression $min '@constant'")
    end
    qts = quote
    end
    qtsv = []
    for m in marray
        if typeof(m) != LineNumberNode
            mnam = m.args[1]
            mval = m.args[2]
            push!(mnames, mnam)
            push!(mvals, mval)
            qt = :($mnam = $mval)
            push!(qtsv, qt)
        else
            push!(qtsv, m)
        end
    end
    return qtsv, mnames, mvals
end

macro observed(oin)
    oarray = []
    onames = []
    ovals = []
    # TODO: Need to develop recursive way to go through all arguments and extract observed names and values. This will allow the code to handle if/else expressions, loops, etc. 
    if oin.head == :block
        orray = oin.args
    elseif oin.head == :(=)
        orray = [oin]
    else
        error("Unrecognized expression $oin in '@observed.'")
    end
    qts = quote
    end
    qtsv = []
    for o in orray
        if typeof(o) != LineNumberNode
            onam = o.args[1]
            oval = o.args[2]
            push!(onames, onam)
            push!(ovals, oval)
            qt = :($onam = $oval)
            push!(qtsv, qt)
        else
            push!(qtsv, o)
        end
    end
    return qtsv, onames, ovals
end
