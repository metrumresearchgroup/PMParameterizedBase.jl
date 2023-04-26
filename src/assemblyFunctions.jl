using ParameterizedModels
using ComponentArrays
using Parameters: @unpack
using MacroTools

function buildInit(initBlock, parameterBlock, constantBlock, repeatedBlock, icBlock)
    fname = gensym("init") # Generate a unique name for the init function
    # TODO: Figure out how to make the line numbers for an error in the initfcn correspond to the original model and not this function...
    pFcn = :(function $fname() end) # Create the skeleton of the init function


    push!(pFcn.args[2].args, initBlock.Block) # Add all of the initBlock code to the init function


    parameterCA_elements = join(["$pn = $pn" for pn in unique(parameterBlock.names)],", ")
    icCA_elements = join(["$vn = $vn" for vn in unique(icBlock.names)],", ")
    constantCA_elements = join(["$an = $an" for an in unique(constantBlock.names)],", ")
    repeatedCA_elements = join(["$dn = $dn" for dn in unique(repeatedBlock.names)],", ")
    parameterCA = string("ComponentArray($parameterCA_elements)")
    icCA = string("ComponentArray($icCA_elements)")
    constantCA = string("ComponentArray($constantCA_elements)")
    repeatedCA = string("ComponentArray($repeatedCA_elements)")
    


    # paramTestLines  = generateCACheckLine(Meta.parse(parameterCA), "Parameter")
    # constantTestLines  = generateCACheckLine(Meta.parse(constantCA), "Constant variable")
    # icTestLines  = generateCACheckLine(Meta.parse(icCA), "IC")
    # repeatedTestLines  = generateCACheckLine(Meta.parse(repeatedCA), "Repeated variable")

    # pFcn.args[2].args = vcat(pFcn.args[2].args, paramTestLines)
    # pFcn.args[2].args = vcat(pFcn.args[2].args, constantTestLines)
    # pFcn.args[2].args = vcat(pFcn.args[2].args, icTestLines)
    # pFcn.args[2].args = vcat(pFcn.args[2].args, repeatedTestLines)
    return_line = string("return (p = $parameterCA,)")

    return_line = Meta.parse(return_line)
    pFcn.args[2].args = vcat(pFcn.args[2].args, [return_line])


    initBlock_noParams = MacroTools.postwalk(x -> @capture(x, @parameter param_) ? nothing : x, initBlock.Block)
    initFcn = :(function $fname(p) end) # Create the skeleton of the init function

    for pn in parameterBlock.names
        push!(initFcn.args[2].args, Meta.parse(string("$pn = p.$pn")))
    end
    push!(initFcn.args[2].args, initBlock_noParams) # Add all of the initBlock code to the init function


    icCA_elements = join(["$vn = $vn" for vn in unique(icBlock.names)],", ")
    constantCA_elements = join(["$an = $an" for an in unique(constantBlock.names)],", ")
    repeatedCA_elements = join(["$dn = $dn" for dn in unique(repeatedBlock.names)],", ")
    icCA = string("ComponentArray($icCA_elements)")
    constantCA = string("ComponentArray($constantCA_elements)")
    repeatedCA = string("ComponentArray($repeatedCA_elements)")

    return_line = string("return (ICs = $icCA, constant = $constantCA, repeated = $repeatedCA)")

    return_line = Meta.parse(return_line)
    initFcn.args[2].args = vcat(initFcn.args[2].args, [return_line])

    return esc(pFcn), esc(initFcn)
end


function generateCACheckLine(CA, type)
    out = quote
        tp = $type
        try $CA
        catch e
            var = e.var
            rethrow(ErrorException("$tp $var is undefined"))
        end
    end
    return out
end