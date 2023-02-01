using PMxSim
using ComponentArrays

mdl_basic = @model function test(du, u, params, t)
    @mrparam p = 2
    @mrstate x = 9
    p
end;

mdl_outofplace = @model function oop(u, params, t)
    @mrparam p = 2
    @mrstate x = 9
end;




