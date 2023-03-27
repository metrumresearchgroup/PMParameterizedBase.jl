using MacroTools
using PMxSim
# @inline Base.getproperty(obj::MRGModel, s::Symbol) = _getindex(Base.maybeview, x, Val(s))

@inline function Base.getproperty(obj::MRGModel, sym::Symbol)
    if sym === :parsed
        ex = getfield(obj,:raw)
        return MacroTools.striplines(ex)
    elseif sym == :states
        ms = collect(methods(obj.model.ICfcn))[1]
        kwargs = Base.kwarg_decl(ms)
        if length(kwargs) > 0
            header = obj.model.__ICheader
            fcncall = copy(header)
            fcncall.args[3] = obj.parameters
            fcncall.args[1] = obj.model.ICfcn
            out = :($(header.args[1])($(header.args[2])) = $fcncall)
            out = eval(out)
        else
            out = obj.model.ICfcn(obj.parameters)
        end
        return out
    elseif sym == :parameters
        ms = collect(methods(obj.model.initFcn))[1]
        kwargs = Base.kwarg_decl(ms)
        if length(kwargs) > 0
            out = (;kwargs...) -> obj.model.initFcn(;kwargs...).p
            # out = obj.model.initFcn.p
        else
            out = obj.model.initFcn().p
        end
    else # fallback to getfield
        return getfield(obj, sym)
    end
end


# " Function to show parsed model with references to original definition and line numbers"
# function show_parsed(mdl::MRGModel)
#     getfield(mdl,:raw)
# end



# function params!(model::MRGModel, params::ComponentArray)
#     for k in keys(params)
#         if hasproperty(model.parameters, k)
#             setproperty!(model.parameters, k, getproperty(params, k))
#         else
#             error("Parameter(s) ", string(k), " not defined in the model")
#         end
#     end
# end

# function params(model::MRGModel, params::ComponentArray)
#     mdl_copy = deepcopy(model)
#     for k in keys(params)
#         if hasproperty(mdl_copy.parameters, k)
#             setproperty!(mdl_copy.parameters, k, getproperty(params, k))
#         else
#             error("Parameter(s) ", string(k), " not defined in the model")
#         end
#     end
#     return mdl_copy
# end


# Write a function to get states. If no kwargs are defined, calculate ICs, if kwargs with default values are defined, use those, otherwise expect a user input.


# @inline function Base.getproperty(obj::MRGModel, sym::Symbol)
#     if sym == :states
#         ms = collect(methods(obj.model.ICfcn))[1]
#         kwargs = Base.kwarg_decl(ms)
#         if length(kwargs) > 0
#             header = obj.model.__ICheader
#             fcncall = copy(header)
#             fcncall.args[3] = obj.parameters
#             out = quote
#                 $(header.args[1])($(header.args[2])) = $fcncall
#             end
#             out = eval(out)
#         else
#             out = obj.model.ICfcn(obj.model.parameters)
#         end
#         return out
#     end
# end

            # return obj.model.ICfc(p = obj.model.parameters)
#             return obj.model.ICfcn(p = obj.model.parameters, )
#         else
#             return g



