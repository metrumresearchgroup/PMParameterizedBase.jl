using PMxSim
using ComponentArrays
using Parameters: @unpack

function buildInit(initBlock, kwargs, pnames, vnames)
    fname = gensym("init") # Generate a unique name for the init function
    initFcn = :(function $fname() end) # Create the skeleton of the init function
    if length(kwargs) > 0 # If there are any keyword arguments, insert them into the init function call
        insert!(initFcn.args[1].args, 2, kwargs...)
    end
    push!(initFcn.args[2].args, initBlock...) # Add all of the initBlock code to the init function

    pCA_elements = join(["$pn = $pn" for pn in pnames],", ")
    vCA_elements = join(["$vn = $vn" for vn in vnames],", ")
    pCA = string("ComponentArray($pCA_elements)")
    vCA = string("ComponentArray($vCA_elements)")
    
    return_line = string("return ComponentArray(p = $pCA, u = $vCA)")
    return_line = Meta.parse(return_line)
    initFcn.args[2].args = vcat(initFcn.args[2].args, [return_line])
    return initFcn
end
