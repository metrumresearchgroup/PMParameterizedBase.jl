using PMxSim
using ComponentArrays
using Parameters: @unpack

function buildInit(initBlock, kwargs, pnames, vnames, static_names; useKwargs = true)
    fname = gensym("init") # Generate a unique name for the init function
    initFcn = :(function $fname() end) # Create the skeleton of the init function
    if length(kwargs) > 0 && useKwargs # If there are any keyword arguments, insert them into the init function call
        insert!(initFcn.args[1].args, 2, kwargs...)
    end
    push!(initFcn.args[2].args, initBlock) # Add all of the initBlock code to the init function

    pCA_elements = join(["$pn = $pn" for pn in pnames],", ")
    vCA_elements = join(["$vn = $vn" for vn in vnames],", ")
    constantCA_elements = join(["$cn = $cn" for cn in static_names],", ")
    pCA = string("ComponentArray($pCA_elements)")
    vCA = string("ComponentArray($vCA_elements)")
    constantCA = string("ComponentArray($constantCA_elements)")
    
    return_line = string("return (p = $pCA, u = $vCA, static_vars = $constanctCA)")
    return_line = Meta.parse(return_line)
    initFcn.args[2].args = vcat(initFcn.args[2].args, [return_line])
    return initFcn
end
