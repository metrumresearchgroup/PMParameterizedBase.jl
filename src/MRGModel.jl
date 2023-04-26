using PMxSim
using Base
using ComponentArrays
using Suppressor
Base.@kwdef struct MRGModelRepr
      pFcn::Function = () -> ()
      initFcn::Function = () -> ()
      __Header::Vector{Any} = Vector{Any}()
      model::Function = () -> ()
      parsed::Expr = :()
      inputs::ComponentArray{<:Number} = ComponentArray{<:Number}()
end



CAorFcn = Union{ComponentArray{<:Number}, Function}
Base.@kwdef mutable struct MRGModel
    parameters::CAorFcn = ComponentArray{Number}()
    states::CAorFcn = ComponentArray{Number}()
    tspan::Tuple = (0.0, 1.0)
    model::MRGModelRepr = MRGModelRepr()
    f::Function = () -> ()
end

# Add a functor for the MRGModel struct to create call to actual model function with substituted inputs.
function (mdl::MRGModel)(du, u, p, t; inputs = :default)
    if inputs == :default
        mdl.f(du, u, p, t, mdl.model.inputs)
    else
        mdl.f(du, u, p, t, inputs)
    end
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
    bodyBlock, derivativeBlock, algebraicBlock, observedBlock, inputs = parseBody(md, inputSym, arguments)
    # println(bodyBlock)
    # Insert parameters into function body
    insertParameters(bodyBlock, parameterBlock, arguments)
    insertStates(bodyBlock, icBlock, arguments)

    # Evalulate the initBlock in a local scope using 'let' to check for any errors before checking for icDdtAgreemnt and parameter overwrites
    initBlockEval = initBlock.Block
    # println(initBlock.Block)
    # initTest = quote
    #     let
    #         $initBlockEval
    #     end

    # end
    # eval(initTest)




    pFcn,initFcn = buildInit(initBlock, parameterBlock, constantBlock, repeatedBlock, icBlock)

    # Get initial param vector and non-zero ICs
    # params = :($pFcn)
    params = :(@suppress $pFcn)
    # params = ComponentArray{Number}()
    # u = ComponentArray{Number}()

    # Build MRGModelRepr object
    bodyFcn = bodyBlock.Block
    # bodyFcn = :(() -> ())
    bodyFcnExpr = :($bodyBlock.Block)
    # bodyFcnExpr = :(() -> ())
    mdl = :(MRGModelRepr($pFcn, $initFcn, $arguments, $bodyFcn, $bodyFcnExpr, $inputs))
    # Build modmrg
    modmrg = :(MRGModel(parameters = ($pFcn)().p, states = ($initFcn)(($pFcn)().p).ICs, model = $mdl, f = $(mdl).model))
        # Check for IC/derivative agreement
        :(icDdtAgreement($icBlock, $derivativeBlock))

        # Check for and warn if parameters are being overwritten in body. 
        :(paramOverwrite($parameterBlock, $algebraicBlock))
    
        # Check for and warn if any other initial assignments are being overwritten in the body
        :(paramOverwrite($initAssignment, $algebraicBlock))
    return modmrg

end

 