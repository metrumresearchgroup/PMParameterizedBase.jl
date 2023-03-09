using PMxSim
using OrdinaryDiffEq: ODEProblem, isinplace

function nonunique(x::AbstractArray{T}) where T
    xs = sort(x)
    duplicatedvector = T[]
    for i = 2:lastindex(xs)
        if (isequal(xs[i],xs[i-1]) && (length(duplicatedvector)==0 || !isequal(duplicatedvector[end], xs[i])))
            push!(duplicatedvector,xs[i])
        end
    end
    duplicatedvector
end

function variable_parameter_overlap(pnames, snames, pvec_symbol, svec_symbol)
    if pvec_symbol == svec_symbol
        error("Parameter and state vectors cannot share a name")
    end
    if !isempty(intersect(pnames, snames))
        overlap = (intersect(pnames, snames))
        # rete = string.("There are both parameters and states named: ", join(overlap,", "))
        error(string.("There are both parameters and states named ", join(overlap,", ", " and ")))
    end
end

function variable_repeat(snames)
    repeated = join(nonunique(snames),", ", " and ")
    if length(repeated) > 0
        error("State(s) $repeated defined multiple times")
    end
end

function parameter_repeat(pnames)
    repeated = join(nonunique(pnames),", ", " and ")
    if length(repeated) > 0 
        error("Parameter(s) $repeated defined multiple times")
    end
end

function derivative_repeat(dnames)
    repeated = join(nonunique(dnames),", ", " and ")
    if length(repeated) > 0
        error("Derivative(s) $repeated defined multiple times")
    end
end

function parameter_vec_rename(pnames, pvec_symbol)
    if any(pnames .== pvec_symbol)
        overlap = findall(pnames .== pvec_symbol)
        overlap = join(overlap,", ", " and ")
        error("Parameter $overlap shares a name with the input parameter vector")
    end
end

function du_inplace(md::Expr)
    header = string(md.args[1])
    qt = string("function ", header, "; ", "end") 
    md_expr = Meta.parse(qt)
    local fcn_tmp = eval(md_expr)
    prob_tmp = ODEProblem(fcn_tmp, nothing, nothing)
    is_inplace = isinplace(prob_tmp)
    return is_inplace
end

