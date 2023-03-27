function parseBody(modfn, args)
    derivatives = Vector{Symbol}() # Create a vector to hold to track which derivatives have bene assigned.
    dynamic_names = Vector{Symbol}() # Create a vector to track dynamic variable assignments. I.e non-state variables that may be updated at every time step.
    body = MacroTools.postwalk(x -> removeInit(x), modfn)
    body_NoDdt = MacroTools.postwalk(x -> removeDdt(x), body)
    MacroTools.postwalk(x -> getRepeatedAssignments(x, dynamic_names), body_NoDdt)
    body = MacroTools.postwalk(x -> walkBodyMacro(x, derivatives, args), body)
    return body, derivatives, dynamic_names
end


function removeInit(x)
    if isexpr(x) && x.head == :macrocall && x.args[1] == Symbol("@init")
        return nothing
    else
        return x
    end
end


function removeDdt(x)
    if isexpr(x) && x.head == :macrocall && x.args[1] == Symbol("@ddt")
        return nothing
    else
        return x
    end
end