using PMxSim
using Base
using ComponentArrays
using Suppressor
Base.@kwdef struct MRGModelRepr
      initFcn::Function = () -> ()
      __Header::Vector{Any} = Vector{Any}()
      model::Function = () -> ()
      parsed::Expr = :()
end


CAorFcn = Union{ComponentArray{<:Number}, Function}
Base.@kwdef mutable struct MRGModel
    parameters::CAorFcn = ComponentArray{Number}()
    states::CAorFcn = ComponentArray{Number}()
    tspan::Tuple = (0.0, 1.0)
    model::MRGModelRepr = MRGModelRepr()
    f::Function = () -> ()
end

Base.@kwdef mutable struct MdlBlock
    names::Vector{Symbol} = Vector{Symbol}()
    Block::Expr = Expr(:block)
    LNN::LineNumberNode = LineNumberNode(0)
    LNNVector::Vector{LineNumberNode} = Vector{LineNumberNode}()
    type::String = ""
    BlockSymbol::Symbol = :nothing
end



Base.@kwdef mutable struct WarnBlock
    LNN::LineNumberNode = LineNumberNode(0)
    LNNVector::Vector{LineNumberNode} = Vector{LineNumberNode}()
    defTypeDict::Dict{String,String} = Dict{String, String}()
    prev::Union{String,Nothing} = ""
end

macro model(md)
    # Parse header to get args and kwargs
    args, kwargs, f, arguments, body = parseHeader(md)

    # Parse initBlock to get parameters, algebraic expressions, dynamic variables and state variables
    initBlock, parameterBlock, icBlock, repeatedBlock, constantBlock, initAssignment = parseInit(md, arguments)

    # Parse body
    inputSym = gensym("input")
    bodyBlock, derivativeBlock, algebraicBlock, observedBlock = parseBody(md, inputSym, arguments)
    # println(bodyBlock)
    # Insert parameters into function body
    insertParameters(bodyBlock, parameterBlock, arguments)
    insertStates(bodyBlock, icBlock, arguments)


    # Check for IC/derivative agreement
    icDdtAgreement(icBlock, derivativeBlock)

    # Check for and warn if parameters are being overwritten in body. 
    paramOverwrite(parameterBlock, algebraicBlock)

    # Check for and warn if any other initial assignments are being overwritten in the body
    paramOverwrite(initAssignment, algebraicBlock)

    initFcn = buildInit(initBlock, parameterBlock, constantBlock, repeatedBlock, icBlock)


    # Get initial param vector and non-zero ICs
    params = :($initFcn) 
    u = :(@suppress $initFcn)
    # params = ComponentArray{Number}()
    # u = ComponentArray{Number}()

    # Build MRGModelRepr object
    bodyFcn = esc(bodyBlock.Block)
    bodyFcnExpr = :($bodyBlock.Block)
    mdl = :(MRGModelRepr($initFcn, $arguments, $bodyFcn, $bodyFcnExpr))
    # Build modmrg
    modmrg = :(MRGModel(parameters = $params, states = $u, model = $mdl, f = $(mdl).model))
    return modmrg

end

