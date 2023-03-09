using PMxSim

macro mrparam(pin)
    parray = []
    pnames = []
    pvals = []
    if pin.head == :block
        parray = pin.args
    elseif pin.head == :(=)
        parray = [pin]
    else
        error("Unrecognized parameter definition")
    end
    qts = quote
          end
    qtsv = []
    for p in parray
        if typeof(p) != LineNumberNode
            pnam = p.args[1]
            pval = p.args[2]
            push!(pnames, pnam)
            push!(pvals, pval)
            qt = :($pnam = $psym.$pnam)
            push!(qtsv, qt)
        else
            push!(qtsv, p)
        end
    end
    return qtsv, pnames, pvals
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
            qt = :($dusym.$dnam = $dval)
            push!(qtsv, qt)
        else
            push!(qtsv, s)
        end
    end
    return qtsv, dnames, dvals
end


