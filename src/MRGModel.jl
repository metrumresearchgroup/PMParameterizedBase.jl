using PMxSim
using Base
using ComponentArrays
using Suppressor
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

Base.@kwdef mutable struct MdlBlock
    node_counter::Int64 = 0
    node_number::Vector{Int64} = Vector{Int64}()
    names::Vector{Symbol} = Vector{Symbol}()
    Block::Expr = Expr(:block)
    LNN::LineNumberNode = LineNumberNode(0)
    LNNVector::Vector{LineNumberNode} = Vector{LineNumberNode}()
    clauses = []
    xPrev::Union{Expr,Symbol,LineNumberNode,Number,Nothing} = :()
end


macro model(md)
    # Parse header to get args and kwargs
    args, kwargs, f, arguments, body = parseHeader(md)

    # Parse initBlock to get parameters, algebraic expressions, dynamic variables and state variables
    initBlock, parameterBlock, constantBlock, repeatedBlock, icBlock = parseInit(md, arguments)

    # Parse body
    


    # Check if kwargs are used to in initFcn
    usedKwargs = kwargsUsedInInit(initBlock.Block, kwargs)
    # Build the initFcn either using kwargs or not
    if length(usedKwargs) > 0
        initFcn = buildInit(initBlock, parameterBlock, constantBlock, repeatedBlock, icBlock, kwargs; useKwargs = true)
    else
        initFcn = buildInit(initBlock, parameterBlock, constantBlock, repeatedBlock, icBlock, kwargs; useKwargs = false)
    end

    # Get initial param vector and non-zero ICs
    params = :($initFcn().p) 
    u = :($initFcn().ICs)


    # Build MRGModelRepr object
    mdl = :(MRGModelRepr($initFcn, $arguments))
    # Build modmrg
    modmrg = :(MRGModel(parameters = $params, states = $u, model = $mdl))
    return modmrg

end

