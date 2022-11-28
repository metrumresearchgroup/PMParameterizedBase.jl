using MacroTools

# @inline Base.getproperty(obj::MRGModel, s::Symbol) = _getindex(Base.maybeview, x, Val(s))
@inline function Base.getproperty(obj::MRGModel, sym::Symbol)
    if sym === :model_raw
        ex = getfield(obj,:model_raw)
        return MacroTools.striplines(ex)
    else # fallback to getfield
        return getfield(obj, sym)
    end
end


" Function to show parsed model with references to original definition and line numbers"
function get_origin(mdl::MRGModel)
    getfield(mdl,:model_raw)
end

