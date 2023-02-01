using PMxSim
using ComponentArrays

mdl_basic = @model function test(du, u, params, t)
    @mrparam p = 2
end;

mdl_outofplace = @model function oop(du, u, params, t)
    @mrparam p = 2
    @mrstate x = 9
end;




