using PMxSim
using Base
using ComponentArrays
Base.@kwdef struct MRGModelRepr
      initFcn::Function = () -> ()
      __Header::Vector{Any} = Vector{Any}()
end


CAorFcn = Union{ComponentArray{<:Number}, Function}
Base.@kwdef mutable struct MRGModel
    parameters::CAorFcn = ComponentArray{Number}()
    states::CAorFcn = ComponentArray{Number}()
    tspan::Tuple = (0.0, 1.0)
    model::MRGModelRepr = MRGModelRepr()
end


macro model(md)
    # Parse header to get args and kwargs
    args, kwargs, f, arguments, body = parseHeader(md)
    pnames, static_names, vnames, initBlock = parseInit(md, arguments)


    # Check if kwargs are used to in initFcn
    usedKwargs = kwargsUsedInInit(initBlock, kwargs)
    if length(usedKwargs) > 0
        initFcn = buildInit(initBlock, kwargs, pnames, vnames, static_names; useKwargs = true)
    else
        initFcn = buildInit(initBlock, kwargs, pnames, vnames, static_names; useKwargs = false)
    end

    params = ComponentVector{Float64}()
    u = ComponentVector{Float64}()
    # TODO: If kwargs>0 maybe these should always be functions to avoid confusion??
    if length(usedKwargs) == 0
        params = :($initFcn().p)
        u = :($initFcn().u)
    else
        params = :($initFcn)
        u = :($initFcn)
    end
    

    mdl = :(MRGModelRepr($initFcn, $arguments))
    modmrg = :(MRGModel(parameters = $params, states = $u, model = $mdl))
    return modmrg
end

