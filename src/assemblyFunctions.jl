using PMxSim
using ComponentArrays
using Parameters: @unpack

function buildInit(initBlock, parameterBlock, constantBlock, repeatedBlock, icBlock, kwargs; useKwargs = true)
    fname = gensym("init") # Generate a unique name for the init function
    initFcn = :(function $fname() end) # Create the skeleton of the init function
    if length(kwargs) > 0 && useKwargs # If there are any keyword arguments, insert them into the init function call
        insert!(initFcn.args[1].args, 2, kwargs...)
    end
    push!(initFcn.args[2].args, initBlock.Block) # Add all of the initBlock code to the init function

    parameterCA_elements = join(["$pn = $pn" for pn in unique(parameterBlock.names)],", ")
    icCA_elements = join(["$vn = $vn" for vn in unique(icBlock.names)],", ")
    constantCA_elements = join(["$an = $an" for an in unique(constantBlock.names)],", ")
    repeatedCA_elements = join(["$dn = $dn" for dn in unique(repeatedBlock.names)],", ")
    parameterCA = string("ComponentArray($parameterCA_elements)")
    icCA = string("ComponentArray($icCA_elements)")
    constantCA = string("ComponentArray($constantCA_elements)")
    repeatedCA = string("ComponentArray($repeatedCA_elements)")
    return_line = string("return (p = $parameterCA, u = $icCA, constant = $constantCA, repeated = $repeatedCA)")
    return_line = Meta.parse(return_line)
    initFcn.args[2].args = vcat(initFcn.args[2].args, [return_line])
    return initFcn
end
