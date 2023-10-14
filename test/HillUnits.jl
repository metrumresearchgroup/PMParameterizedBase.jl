@parameters t [unit = u"s"] kC50 [unit=u"nmol*L^-1"] γ kmax [unit = u"s^-1"]
@variables Trimer(t)

function Hill(E, Km, gamma)
    return E^gamma / (Km^gamma + E^gamma)
end

@register_symbolic Hill(E, Km, γ)

function ModelingToolkit.get_unit(op::typeof(Hill), args)
       return ModelingToolkit.unitless
end

kapop = kmax * Hill(Trimer, kC50, γ)
ModelingToolkit.get_unit(kapop)

