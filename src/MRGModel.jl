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


    # Check if kwargs are used to in initFcn
    usedKwargs = kwargsUsedInInit(initBlock.Block, kwargs)
    if length(usedKwargs) > 0
        initFcn = buildInit(initBlock, parameterBlock, constantBlock, repeatedBlock, icBlock, kwargs; useKwargs = true)
    else
        initFcn = buildInit(initBlock, parameterBlock, constantBlock, repeatedBlock, icBlock, kwargs; useKwargs = false)
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

    # body, derivatives, repeated_names = parseBody(md, args)
    # # println(body)

    # mdl = :(MRGModelRepr($initFcn, $arguments))
    # modmrg = :(MRGModel(parameters = $params, states = $u, model = $mdl))
    # return modmrg
end

